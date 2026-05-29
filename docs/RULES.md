# Regras do Projeto

## Principios

- Codigo simples e direto ao ponto.
- Arquitetura moderna, modular e previsivel.
- Otimizacao intencional, sem sacrificar clareza.
- Sem gambiarras, atalhos ocultos ou comportamento magico.

## Codigo

- Cada arquivo deve ter uma responsabilidade clara.
- Cada funcao deve fazer uma coisa bem definida.
- Usar nomes claros e sem abreviacoes desnecessarias.
- Evitar duplicacao, codigo morto e comentarios obsoletos.
- Preferir contratos explicitos e falhas visiveis.

## API

- APIs modulares devem ficar em `source/api`.
- A API publica deve ser simples, elegante e facil de usar.
- Tipagem forte e explicita e obrigatoria nos handles e contratos expostos.
- Criar classes, subclasses e modos deve ser muito facil.
- O estilo visual da API deve seguir a organizacao simples do ReZombie C++.
- Manter handles tipados no Pawn, como `Class:`, `Subclass:` e `Props:`.
- Manter propriedades por string, como `get_class_var(class, "props")`.
- Manter setters claros, como `set_props_var(props, "health", 700)`.
- Manter natives agrupadas por categoria no include publico.
- Natives de zombie devem ficar junto da categoria Zombie.
- Natives de humano devem ficar junto da categoria Human.
- Comentarios de natives devem estar em ingles no padrao AMXX/CS 1.6.
- Validar nomes de propriedades e tipos sem fallback silencioso.

## Tags e Tipagem

- Todo handle publico deve possuir tag Pawn explicita.
- `null` deve ser tipado como `any:null = 0`.
- `0` nao deve ser usado diretamente como handle invalido.
- Funcoes `Require*` devem falhar de forma explicita quando o recurso nao existir.
- Funcoes `Find*` podem retornar `null` para buscas opcionais.

## Erros

- Todo erro deve ser explicito, claro e rastreavel.
- Nenhum erro invisivel.
- Nenhum fallback silencioso.
- Falhas de inicializacao devem parar o fluxo com uma mensagem clara.

## Evolucao

- Implementar somente o necessario para o proximo passo real.
- Validar em runtime antes de expandir.
- Evoluir por etapas pequenas, completas e funcionais.
- Atualizar `docs/TODO.md` sempre que uma etapa mudar.
- Comitar cada mudanca logica concluida e validada.
