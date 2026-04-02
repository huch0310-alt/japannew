-- 创建商品图片bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true);

-- 创建PDF存储bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', false);

-- 配置Storage策略
CREATE POLICY "Anyone can view product images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload product images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Sales can manage pdfs"
    ON storage.objects FOR ALL
    USING (bucket_id = 'pdfs');
