import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Header */}
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container flex h-16 items-center justify-between">
          <div className="flex gap-6 md:gap-10">
            <Link href="/" className="flex items-center space-x-2">
              <span className="inline-block font-bold text-xl">Jabez</span>
            </Link>
            <nav className="hidden md:flex gap-6">
              <Link href="/categories" className="text-sm font-medium transition-colors hover:text-foreground/80">
                Categorias
              </Link>
              <Link href="/platforms" className="text-sm font-medium transition-colors hover:text-foreground/80">
                Plataformas
              </Link>
            </nav>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/login">
              <Button variant="ghost" size="sm">Entrar</Button>
            </Link>
            <Link href="/login?mode=signup">
              <Button size="sm">Anunciar Plataforma</Button>
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1">
        {/* Hero Section */}
        <section className="space-y-6 pb-8 pt-16 md:pb-12 md:pt-24 lg:py-32 text-center">
          <div className="container flex max-w-[64rem] flex-col items-center gap-4 text-center">
            <h1 className="font-heading text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight">
              Encontre a melhor ferramenta para o seu negócio
            </h1>
            <p className="max-w-[42rem] leading-normal text-muted-foreground sm:text-xl sm:leading-8">
              Compare centenas de plataformas SaaS, IA e automações em um só lugar. Encontre a solução ideal para acelerar seu crescimento.
            </p>
            <div className="space-x-4 mt-6">
              <Link href="/platforms">
                <Button size="lg" className="px-8">Explorar Ferramentas</Button>
              </Link>
              <Link href="/login?mode=signup">
                <Button size="lg" variant="outline" className="px-8">Anunciar Plataforma</Button>
              </Link>
            </div>
          </div>
        </section>

        {/* Categories Section */}
        <section className="container space-y-6 py-8 md:py-12 lg:py-24">
          <div className="mx-auto flex max-w-[58rem] flex-col items-center space-y-4 text-center">
            <h2 className="font-heading text-3xl leading-[1.1] sm:text-3xl md:text-5xl font-bold">Categorias</h2>
            <p className="max-w-[85%] leading-normal text-muted-foreground sm:text-lg sm:leading-7">
              Navegue pelas categorias e encontre ferramentas especialistas no que você precisa.
            </p>
          </div>
          <div className="mx-auto grid justify-center gap-4 sm:grid-cols-2 md:max-w-[64rem] md:grid-cols-4">
            {['IA', 'CRM', 'ERP', 'WhatsApp', 'Marketing', 'Automação', 'Atendimento', 'Financeiro'].map((cat) => (
              <Link href={`/categories/${cat.toLowerCase()}`} key={cat}>
                <div className="relative overflow-hidden rounded-lg border bg-background p-6 transition-colors hover:bg-muted/50 cursor-pointer">
                  <div className="font-bold text-center">{cat}</div>
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* Featured Platforms */}
        <section className="container space-y-6 py-8 md:py-12 lg:py-24">
          <div className="mx-auto flex max-w-[58rem] flex-col items-center space-y-4 text-center">
            <h2 className="font-heading text-3xl leading-[1.1] sm:text-3xl md:text-5xl font-bold">Ferramentas em Destaque</h2>
            <p className="max-w-[85%] leading-normal text-muted-foreground sm:text-lg sm:leading-7">
              As plataformas mais avaliadas e utilizadas do mercado.
            </p>
          </div>
          <div className="mx-auto grid justify-center gap-4 sm:grid-cols-2 md:max-w-[64rem] md:grid-cols-3">
             {/* Placeholder Cards */}
             {[1, 2, 3].map((item) => (
                <div key={item} className="flex flex-col rounded-lg border bg-card text-card-foreground shadow-sm">
                  <div className="p-6 flex flex-col items-center gap-4">
                    <div className="h-16 w-16 bg-muted rounded-md" />
                    <h3 className="font-semibold text-xl">Plataforma Exemplo</h3>
                    <div className="text-sm text-muted-foreground">Categoria</div>
                    <div className="flex items-center text-yellow-500">
                      ★ 4.9 (120)
                    </div>
                    <Button className="w-full mt-4">Ver Detalhes</Button>
                  </div>
                </div>
             ))}
          </div>
        </section>
      </main>

      <footer className="border-t py-6 md:py-0">
        <div className="container flex flex-col items-center justify-between gap-4 md:h-24 md:flex-row">
          <p className="text-center text-sm leading-loose text-muted-foreground md:text-left">
            © 2024 Jabez Marketplace. Todos os direitos reservados.
          </p>
        </div>
      </footer>
    </div>
  )
}
