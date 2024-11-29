-- Reset existing tables and policies
drop policy if exists "Users can view their own products" on products;
drop policy if exists "Users can insert their own products" on products;
drop policy if exists "Users can update their own products" on products;
drop policy if exists "Users can delete their own products" on products;

-- Create RLS policies for products
create policy "Users can view their own products"
  on products for select
  using (auth.uid() = user_id);

create policy "Users can insert their own products"
  on products for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own products"
  on products for update
  using (auth.uid() = user_id);

create policy "Users can delete their own products"
  on products for delete
  using (auth.uid() = user_id);

-- Enable RLS on products table
alter table products enable row level security;