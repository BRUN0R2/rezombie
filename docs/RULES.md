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
