alter table public.products add column if not exists image_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "product users upload product images"
on storage.objects for insert to authenticated
with check (bucket_id = 'product-images' and public.has_permission('products'));

create policy "product users update product images"
on storage.objects for update to authenticated
using (bucket_id = 'product-images' and public.has_permission('products'))
with check (bucket_id = 'product-images' and public.has_permission('products'));

create policy "product users delete product images"
on storage.objects for delete to authenticated
using (bucket_id = 'product-images' and public.has_permission('products'));
