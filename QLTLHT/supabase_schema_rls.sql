-- ==============================================================================
-- DỰ ÁN QUẢN LÝ TÀI LIỆU HỌC TẬP ĐA NỀN TẢNG (QLTLHT)
-- HỆ THỐNG CƠ SỞ DỮ LIỆU SUPABASE & CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- 1. KÍCH HOẠT EXTENSION UUID (NẾU CẦN)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TẠO CÁC BẢNG DỮ LIỆU QUAN HỆ (TABLES)
-- ==============================================================================

-- BẢNG 1: NGƯỜI DÙNG (users)
-- Lưu thông tin tài khoản được đồng bộ từ Firebase Authentication (Google Sign-In)
CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(128) PRIMARY KEY, -- Firebase Auth UID
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- BẢNG 2: MÔN HỌC (subjects - tùy chọn để liên kết danh mục môn học trên Cloud)
CREATE TABLE IF NOT EXISTS public.subjects (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    color BIGINT DEFAULT 4280391411,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- BẢNG 3: DANH MỤC TÀI LIỆU (categories)
CREATE TABLE IF NOT EXISTS public.categories (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    color BIGINT DEFAULT 4280391411,
    icon_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- BẢNG 4: TÀI LIỆU (documents)
-- Lưu metadata của tài liệu, liên kết với tệp tin vật lý trên Firebase Storage
CREATE TABLE IF NOT EXISTS public.documents (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) NOT NULL DEFAULT 'PDF',
    file_url TEXT,                      -- Download URL từ Firebase Storage
    storage_path TEXT,                  -- Đường dẫn tệp: documents/{owner_id}/{id}/{file_name}
    file_size BIGINT DEFAULT 0,         -- Kích thước tệp (bytes)
    subject_id VARCHAR(64),
    category_id VARCHAR(64),
    tags TEXT DEFAULT '',
    is_favorite BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    owner_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- BẢNG 5: QUYỀN CHIA SẺ TÀI LIỆU (document_permissions)
-- Quản lý phân quyền truy cập theo vai trò (Role-Based / Document-Level Sharing)
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    permission_level VARCHAR(20) NOT NULL CHECK (permission_level IN ('view', 'edit', 'admin')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT unique_doc_user_permission UNIQUE (document_id, user_id)
);

-- ==============================================================================
-- 3. CHỈ MỤC TỐI ƯU HÓA TRUY VẤN (INDEXES)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_title ON public.documents(title);
CREATE INDEX IF NOT EXISTS idx_doc_perm_user ON public.document_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_doc_perm_doc ON public.document_permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- ==============================================================================
-- 4. KÍCH HOẠT CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- Hàm hỗ trợ lấy UID của người dùng hiện tại từ JWT (hỗ trợ cả Supabase Auth và Firebase Token)
CREATE OR REPLACE FUNCTION current_auth_uid()
RETURNS text AS $$
BEGIN
    -- Lấy từ auth.jwt() sub claim hoặc header 'x-firebase-uid'
    RETURN COALESCE(
        current_setting('request.jwt.claim.sub', true),
        current_setting('request.headers', true)::json->>'x-firebase-uid',
        auth.uid()::text
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ------------------------------------------------------------------------------
-- RLS POLICIES CHO BẢNG USERS
-- ------------------------------------------------------------------------------

-- Cho phép người dùng đọc danh sách người dùng để hỗ trợ tìm kiếm khi chia sẻ tài liệu
DROP POLICY IF EXISTS "Cho phép đọc thông tin người dùng" ON public.users;
CREATE POLICY "Cho phép đọc thông tin người dùng"
    ON public.users FOR SELECT
    USING (true);

-- Cho phép người dùng thêm hoặc cập nhật thông tin chính mình
DROP POLICY IF EXISTS "Người dùng tự cập nhật thông tin cá nhân" ON public.users;
CREATE POLICY "Người dùng tự cập nhật thông tin cá nhân"
    ON public.users FOR ALL
    USING (id = current_auth_uid())
    WITH CHECK (id = current_auth_uid());

-- ------------------------------------------------------------------------------
-- RLS POLICIES CHO BẢNG DOCUMENTS
-- ------------------------------------------------------------------------------

-- 1. XEM TÀI LIỆU (SELECT):
-- Điều kiện: Người dùng là Chủ sở hữu (Owner) HOẶC có bản ghi trong bảng permissions
DROP POLICY IF EXISTS "Xem tài liệu của mình hoặc được chia sẻ" ON public.documents;
CREATE POLICY "Xem tài liệu của mình hoặc được chia sẻ"
    ON public.documents FOR SELECT
    USING (
        owner_id = current_auth_uid()
        OR
        EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
            AND dp.user_id = current_auth_uid()
        )
    );

-- 2. TẠO TÀI LIỆU (INSERT):
-- Điều kiện: Chỉ có thể tạo tài liệu với owner_id trùng khớp với current user
DROP POLICY IF EXISTS "Chỉ tạo tài liệu với quyền sở hữu cá nhân" ON public.documents;
CREATE POLICY "Chỉ tạo tài liệu với quyền sở hữu cá nhân"
    ON public.documents FOR INSERT
    WITH CHECK (
        owner_id = current_auth_uid()
    );

-- 3. CẬP NHẬT TÀI LIỆU (UPDATE):
-- Điều kiện: Chủ sở hữu (Owner) HOẶC người dùng được cấp quyền 'edit' / 'admin'
DROP POLICY IF EXISTS "Cập nhật tài liệu bởi chủ sở hữu hoặc người có quyền edit" ON public.documents;
CREATE POLICY "Cập nhật tài liệu bởi chủ sở hữu hoặc người có quyền edit"
    ON public.documents FOR UPDATE
    USING (
        owner_id = current_auth_uid()
        OR
        EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
            AND dp.user_id = current_auth_uid()
            AND dp.permission_level IN ('edit', 'admin')
        )
    )
    WITH CHECK (
        owner_id = current_auth_uid()
        OR
        EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
            AND dp.user_id = current_auth_uid()
            AND dp.permission_level IN ('edit', 'admin')
        )
    );

-- 4. XÓA TÀI LIỆU (DELETE):
-- Điều kiện: CHỈ DUY NHẤT Chủ sở hữu (Owner) mới có quyền xóa tài liệu
DROP POLICY IF EXISTS "Chỉ chủ sở hữu mới có quyền xóa tài liệu" ON public.documents;
CREATE POLICY "Chỉ chủ sở hữu mới có quyền xóa tài liệu"
    ON public.documents FOR DELETE
    USING (
        owner_id = current_auth_uid()
    );

-- ------------------------------------------------------------------------------
-- RLS POLICIES CHO BẢNG DOCUMENT_PERMISSIONS
-- ------------------------------------------------------------------------------

-- 1. XEM QUYỀN TRUY CẬP (SELECT):
-- Điều kiện: Là Chủ sở hữu tài liệu HOẶC là người được gán quyền đó
DROP POLICY IF EXISTS "Xem danh sách quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Xem danh sách quyền chia sẻ"
    ON public.document_permissions FOR SELECT
    USING (
        user_id = current_auth_uid()
        OR
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = public.document_permissions.document_id
            AND d.owner_id = current_auth_uid()
        )
    );

-- 2. CẤP QUYỀN CHIA SẺ (INSERT):
-- Điều kiện: Chỉ Chủ sở hữu của tài liệu mới có quyền chia sẻ cho người khác
DROP POLICY IF EXISTS "Chủ sở hữu cấp quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu cấp quyền chia sẻ"
    ON public.document_permissions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = public.document_permissions.document_id
            AND d.owner_id = current_auth_uid()
        )
    );

-- 3. THAY ĐỔI CẤP ĐỘ QUYỀN (UPDATE):
-- Điều kiện: Chỉ Chủ sở hữu tài liệu mới được thay đổi quyền (từ view sang edit, v.v.)
DROP POLICY IF EXISTS "Chủ sở hữu thay đổi quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu thay đổi quyền chia sẻ"
    ON public.document_permissions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = public.document_permissions.document_id
            AND d.owner_id = current_auth_uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = public.document_permissions.document_id
            AND d.owner_id = current_auth_uid()
        )
    );

-- 4. THU HỒI QUYỀN CHIA SẺ (DELETE):
-- Điều kiện: Chỉ Chủ sở hữu tài liệu mới có quyền thu hồi chia sẻ
DROP POLICY IF EXISTS "Chủ sở hữu thu hồi quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu thu hồi quyền chia sẻ"
    ON public.document_permissions FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.documents d
            WHERE d.id = public.document_permissions.document_id
            AND d.owner_id = current_auth_uid()
        )
    );

-- ==============================================================================
-- 5. TRIGGER TỰ ĐỘNG CẬP NHẬT UPDATED_AT
-- ==============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON public.users;
CREATE TRIGGER trigger_update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_update_documents_updated_at ON public.documents;
CREATE TRIGGER trigger_update_documents_updated_at
    BEFORE UPDATE ON public.documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_update_doc_perm_updated_at ON public.document_permissions;
CREATE TRIGGER trigger_update_doc_perm_updated_at
    BEFORE UPDATE ON public.document_permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- 6. DỮ LIỆU MẪU KIỂM THỬ (TEST SEED DATA) CHO 3 TÀI KHOẢN NGƯỜI DÙNG
-- ==============================================================================
INSERT INTO public.users (id, email, display_name, photo_url)
VALUES 
    ('usr_alice_owner_101', 'alice.owner@student.edu.vn', 'Alice (Chủ sở hữu)', 'https://api.dicebear.com/7.x/bottts/svg?seed=Alice'),
    ('usr_bob_viewer_202', 'bob.viewer@student.edu.vn', 'Bob (Người xem - Viewer)', 'https://api.dicebear.com/7.x/bottts/svg?seed=Bob'),
    ('usr_charlie_editor_303', 'charlie.editor@student.edu.vn', 'Charlie (Chỉnh sửa - Editor)', 'https://api.dicebear.com/7.x/bottts/svg?seed=Charlie')
ON CONFLICT (id) DO NOTHING;
