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
- Investigar a fonte real do problema antes de corrigir sintomas.
- Resolver problemas diretamente na fonte, sem flags temporarias ou contornos escondidos.
- Evitar numeros magicos, principalmente em parametros posicionais de natives.
- Parametros posicionais de natives devem usar nomes semanticos via `enum`.
- Todo plugin `.sma` deve usar `#pragma semicolon 1` e `#pragma compress 1`.

## API

- APIs modulares devem ficar em `source/api`.
- Includes internos modulares devem ficar em `include/rezombie/<modulo>`.
- Codigo em `source` deve usar includes padrao, sem caminhos relativos entre pastas.
- Stocks genericos reutilizaveis devem ficar em `include/rezombie_stock.inc`.
- `rezombie_stock.inc` nao deve receber regras de negocio ou estado de modulo.
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
- Forwards publicos devem usar retornos proprios da API, como `RZ_CONTINUE` e `RZ_SUPERCEDE`.
- Bloquear comportamentos padrao do CS/GameDLL que conflitem com o mod antes de aplicar runtime proprio.
- Nao misturar entrega padrao do jogo com entrega do mod quando o mod for dono do fluxo.

## Ambiente

- O projeto deve usar ReHLDS, ReGameDLL e ReAPI.
- ReHLDS, ReGameDLL e ReAPI devem estar nas versoes estaveis mais recentes disponiveis.
- Integracoes com ReHLDS, ReGameDLL e ReAPI devem ser explicitas e isoladas.
- Evitar dependencias em comportamento legado quando ReAPI oferecer contrato moderno.

## Round e Tempo

- Contagem de round, inicio de infeccao e checks de vitoria devem usar hook explicito de frame do servidor.
- Timings de gameplay devem usar tempo absoluto, como `get_gametime()`, para evitar descompasso com variacao de FPS.
- Preferir `FM_StartFrame` registrado de forma explicita quando o fluxo depender de tick/frame continuo.
- Nao usar `set_task` para controlar countdown, inicio de infeccao ou fluxo principal de round.

## Tags e Tipagem

- Todo handle publico deve possuir tag Pawn explicita.
- `null` deve ser tipado como `any:null = 0`.
- `0` nao deve ser usado diretamente como handle invalido.
- Retornos `any:` devem preservar tags Pawn quando o valor original for tipado.
- Nao usar `_:` em retornos `any:` apenas para remover warnings ou simplificar.
- Usar `_:` somente em fronteiras internas que exigem celula crua, como logs formatados ou indice derivado de handle.
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
