-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Enable RLS (Row Level Security)
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.users enable row level security;
alter table public.settings enable row level security;
alter table public.transactions enable row level security;

-- Create users table
create table public.users (
  id uuid references auth.users primary key,
  email text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create settings table
create table public.settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users not null,
  language text default 'fr',
  email_notifications boolean default true,
  push_notifications boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create products table
create table public.products (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  brand text not null,
  purchase_price decimal not null,
  purchase_date timestamp with time zone not null,
  image_url text not null,
  status text not null check (status in ('in_stock', 'sold')),
  sale_price decimal,
  sale_date timestamp with time zone,
  category text not null check (category in ('sneakers', 'clothing', 'objects', 'tickets')),
  description text,
  user_id uuid references public.users not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create orders table
create table public.orders (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  brand text not null,
  purchase_price decimal not null,
  purchase_date timestamp with time zone not null,
  image_url text not null,
  category text not null check (category in ('sneakers', 'clothing', 'objects', 'tickets')),
  description text,
  status text not null check (status in ('pending', 'ordered')),
  seller_name text,
  seller_phone text,
  seller_email text,
  user_id uuid references public.users not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create transactions table
create table public.transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users not null,
  product_id uuid references public.products,
  order_id uuid references public.orders,
  type text not null check (type in ('purchase', 'sale')),
  amount decimal not null,
  date timestamp with time zone not null,
  created_at timestamp with time zone default now()
);

-- Create policies for users
create policy "Users can view their own data"
  on users for select
  using (auth.uid() = id);

create policy "Users can update their own data"
  on users for update
  using (auth.uid() = id);

-- Create policies for settings
create policy "Users can view their own settings"
  on settings for select
  using (auth.uid() = user_id);

create policy "Users can update their own settings"
  on settings for update
  using (auth.uid() = user_id);

create policy "Users can insert their own settings"
  on settings for insert
  with check (auth.uid() = user_id);

-- Create policies for products
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

-- Create policies for orders
create policy "Users can view their own orders"
  on orders for select
  using (auth.uid() = user_id);

create policy "Users can insert their own orders"
  on orders for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own orders"
  on orders for update
  using (auth.uid() = user_id);

create policy "Users can delete their own orders"
  on orders for delete
  using (auth.uid() = user_id);

-- Create policies for transactions
create policy "Users can view their own transactions"
  on transactions for select
  using (auth.uid() = user_id);

create policy "Users can insert their own transactions"
  on transactions for insert
  with check (auth.uid() = user_id);

-- Create triggers for updated_at columns
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create triggers for each table
create trigger update_users_updated_at
  before update on users
  for each row
  execute function update_updated_at_column();

create trigger update_settings_updated_at
  before update on settings
  for each row
  execute function update_updated_at_column();

create trigger update_products_updated_at
  before update on products
  for each row
  execute function update_updated_at_column();

create trigger update_orders_updated_at
  before update on orders
  for each row
  execute function update_updated_at_column();

-- Create function to handle user creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email);

  insert into public.settings (user_id)
  values (new.id);

  return new;
end;
$$ language plpgsql security definer;

-- Create trigger to automatically create user profile and settings
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();