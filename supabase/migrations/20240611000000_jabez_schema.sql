-- ==========================================
-- JABEZ - Supabase Schema
-- ==========================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. FUNCTIONS & TRIGGERS (Core)
-- Auto-update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TABLES
-- profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    avatar TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_profiles_modtime
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- platforms
CREATE TABLE public.platforms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    short_description TEXT,
    description TEXT,
    website TEXT,
    logo TEXT,
    cover_image TEXT,
    pricing_model TEXT,
    approved BOOLEAN DEFAULT FALSE,
    featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_platforms_modtime
BEFORE UPDATE ON public.platforms
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- platform_images
CREATE TABLE public.platform_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- reviews
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- favorites
CREATE TABLE public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- leads
CREATE TABLE public.leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    phone TEXT,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- plans
CREATE TABLE public.plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    price_monthly NUMERIC NOT NULL,
    features JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- subscriptions
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES public.plans(id),
    status TEXT NOT NULL, -- active, canceled, past_due
    stripe_subscription_id TEXT,
    mercadopago_subscription_id TEXT,
    started_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- payments
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE,
    provider TEXT, -- stripe, mercadopago
    provider_payment_id TEXT,
    amount NUMERIC NOT NULL,
    currency TEXT DEFAULT 'BRL',
    status TEXT NOT NULL, -- paid, pending, failed
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- audit_logs
CREATE TABLE public.audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    old_data JSONB,
    new_data JSONB,
    performed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. INDEXES
CREATE INDEX idx_platforms_category_approved ON public.platforms(category_id, approved);
CREATE INDEX idx_platforms_featured_approved ON public.platforms(featured, approved);
CREATE INDEX idx_reviews_platform ON public.reviews(platform_id);
CREATE INDEX idx_favorites_user ON public.favorites(user_id);
CREATE INDEX idx_leads_platform_created ON public.leads(platform_id, created_at);
CREATE INDEX idx_subscriptions_user_status ON public.subscriptions(user_id, status);

-- 5. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone can read, users can update their own
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Categories: Read-only for public, admin for mutations
CREATE POLICY "Categories are viewable by everyone" ON public.categories FOR SELECT USING (true);

-- Platforms: Viewable if approved or owner, create if authenticated, update if owner
CREATE POLICY "Platforms viewable by public if approved or owner" ON public.platforms FOR SELECT USING (approved = true OR auth.uid() = owner_id);
CREATE POLICY "Authenticated can create platforms" ON public.platforms FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update their platforms" ON public.platforms FOR UPDATE USING (auth.uid() = owner_id);

-- Platform Images: Public read
CREATE POLICY "Platform images are public" ON public.platform_images FOR SELECT USING (true);
CREATE POLICY "Owners can manage platform images" ON public.platform_images FOR ALL USING (
    EXISTS (SELECT 1 FROM public.platforms WHERE id = platform_images.platform_id AND owner_id = auth.uid())
);

-- Reviews: Public read, auth create
CREATE POLICY "Reviews are public" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can insert reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Favorites: User can only see/manage their own
CREATE POLICY "Users manage own favorites" ON public.favorites FOR ALL USING (auth.uid() = user_id);

-- Leads: Anyone can insert, only platform owner can view
CREATE POLICY "Anyone can create leads" ON public.leads FOR INSERT WITH CHECK (true);
CREATE POLICY "Owners can view leads for their platforms" ON public.leads FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.platforms WHERE id = leads.platform_id AND owner_id = auth.uid())
);

-- Plans: Public read
CREATE POLICY "Plans are public" ON public.plans FOR SELECT USING (true);

-- Subscriptions & Payments: Users can see their own
CREATE POLICY "Users can see own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can see own payments" ON public.payments FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.subscriptions WHERE id = payments.subscription_id AND user_id = auth.uid())
);

-- Audit Logs: Admin only (Example policy)
CREATE POLICY "Only admins view audit logs" ON public.audit_logs FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 6. TRIGGERS (Auth)
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, avatar, role)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'name',
        new.raw_user_meta_data->>'avatar_url',
        'user'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. AUDIT TRIGGER
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    uid UUID := auth.uid();
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id::text, TG_OP, row_to_json(NEW), uid);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, new_data, performed_by)
        VALUES (TG_TABLE_NAME, NEW.id::text, TG_OP, row_to_json(OLD), row_to_json(NEW), uid);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_logs (table_name, record_id, action, old_data, performed_by)
        VALUES (TG_TABLE_NAME, OLD.id::text, TG_OP, row_to_json(OLD), uid);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add audit triggers to important tables
CREATE TRIGGER audit_platforms_trigger AFTER INSERT OR UPDATE OR DELETE ON public.platforms FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
CREATE TRIGGER audit_profiles_trigger AFTER UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- 8. INITIAL DATA
INSERT INTO public.categories (name, slug, icon) VALUES 
('IA', 'ia', 'BrainCircuit'),
('WhatsApp', 'whatsapp', 'MessageCircle'),
('CRM', 'crm', 'Users'),
('Automação', 'automacao', 'Zap'),
('Marketing', 'marketing', 'Megaphone'),
('Financeiro', 'financeiro', 'DollarSign'),
('Vendas', 'vendas', 'TrendingUp'),
('Atendimento', 'atendimento', 'Headphones')
ON CONFLICT (slug) DO NOTHING;
