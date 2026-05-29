# TODO

## Concluido

- [x] Estudar Zombie Plague Next como referencia de logica AMXPawn simples.
- [x] Estudar ReZombie C++ como referencia de arquitetura, hooks e modernizacao.
- [x] Inicializar o repositorio Git local.
- [x] Criar regras iniciais do projeto.
- [x] Criar `source/api` para APIs modulares.
- [x] Validar compilacao inicial da API e classes sem erros.
- [x] Reestudar Infection no Zombie Plague Next e ReZombie C++.
- [x] Definir que modos devem ser finos e o round deve ficar no core.
- [x] Corrigir APIs modulares para plugins `.sma` em `source/api`.
- [x] Separar `ApiClasses`, `ApiSubclasses` e `ApiProps`.
- [x] Criar API modular de modelos para `Model:`.
- [x] Documentar a ordem inicial de carregamento dos plugins.
- [x] Criar `build.bat` para gerar o pacote local em `build/cstrike`.
- [x] Criar `start.bat` para abrir o servidor visivel em primeiro plano.
- [x] Gerar `plugins-rezombie.ini` com a ordem correta do mod.
- [x] Organizar `plugins-rezombie.ini` por categorias.
- [x] Corrigir leitura de parametros `any:...` nas APIs modulares.

## Proxima Meta

- [ ] Criar uma base inicial funcional, simples, limpa e enxuta.
- [ ] Manter a primeira versao focada em jogador, round e infeccao.
- [ ] Reimplementar somente o que fizer sentido para este projeto novo.
- [x] Separar API de classes e API de modos por responsabilidade.
- [x] Criar um core de round centralizado antes de recriar o modo Infection.
- [x] Recriar Infection como modo fino, sem responsabilidades de round.

## Base Inicial

- [x] Definir a estrutura minima dos modulos em `source`.
- [x] Implementar APIs modulares em `source/api`.
- [x] Preparar integracao com ReHLDS, ReGameDLL e ReAPI atualizados.
- [x] Criar o nucleo de estado do jogador: humano, zombie, vivo e conectado.
- [x] Criar a API publica minima em `include/rezombie.inc`.
- [x] Criar handles tipados para `Class:`, `Subclass:`, `Props:` e `Mode:`.
- [x] Criar handle tipado para `Model:`.
- [x] Criar `new const any:null = 0` como nulo tipado da API.
- [x] Criar `FindClass` e `RequireClass`.
- [x] Organizar natives por categoria no include publico.
- [x] Documentar natives em ingles no padrao AMXX/CS 1.6.
- [x] Criar `get_class_var` e `set_class_var`.
- [x] Criar `get_subclass_var` e `set_subclass_var`.
- [x] Criar `get_props_var` e `set_props_var`.
- [x] Criar `get_player_class` e `get_player_subclass`.
- [x] Criar `get_player_var` e `set_player_var` com estado seguro.
- [x] Criar `change_player_class`.
- [x] Criar `infect_player`.
- [x] Criar API modular de props para `Props:`.
- [x] Criar API modular de modelos para `Model:`.
- [x] Criar API modular de classes para `Class:`.
- [x] Criar API modular de subclasses para `Subclass:`.
- [x] Mover registro, busca e variaveis de classes para `ApiClasses`.
- [x] Mover registro, busca e variaveis de subclasses para `ApiSubclasses`.
- [x] Mover registro e variaveis de props para `ApiProps`.
- [x] Criar API modular de modos para `Mode:`.
- [x] Criar API/registro de modos com `create_mode`, `get_mode_var`, `set_mode_var` e `launch_mode`.
- [x] Criar leitura de modos registrados com `get_modes_count` e `get_mode`.
- [x] Recriar o primeiro modo de jogo: infeccao.
- [x] Precachear apenas os recursos usados pela primeira versao.
- [x] Usar `rz_source` como modelo zombie padrao.
- [x] Evitar fallback silencioso quando zombie estiver sem modelo runtime.
- [x] Criar `fleshpound` como primeira subclass zombie com modelo proprio.
- [x] Criar runtime dev separado para validacao manual por IA/Codex.
- [x] Criar validacao runtime completa de classe, infeccao e restart.
- [x] Criar forwards minimos de player e round.
- [x] Criar retornos proprios para forwards `pre`.
- [x] Validar bloqueio de forwards `pre` com `RZ_SUPERCEDE`.
- [x] Aplicar itens padrao ao trocar classe.
- [x] Criar modulo visual minimo para feedback de round.

## APIs Modulares

- [x] Manter cada API com uma responsabilidade clara.
- [x] API de props: criar e configurar props.
- [x] API de modelos: criar, buscar e precachear modelos.
- [x] API de classes: criar, buscar, exigir e configurar classes.
- [x] API de subclasses: criar, buscar, exigir e configurar subclasses.
- [x] API de modos: criar, buscar, configurar e lancar modos.
- [x] API de jogadores: estado, classe atual, infeccao, humano e zombie.
- [x] API de jogadores: expor variaveis seguras do estado do jogador.
- [x] API de jogadores: expor forwards de classe e infeccao.
- [x] Usar `Trie` para lookup rapido de handles mantendo `Array` como storage.
- [x] Evitar uma API central acumulando responsabilidades diferentes.

## Round Core

- [x] Usar a logica simples do Zombie Plague Next como referencia principal.
- [x] Usar o ReZombie C++ como referencia de separacao entre GameRules e Mode.
- [x] Criar `source/core/GameRules.sma` como dono do ciclo do round.
- [x] Controlar estados do round: aguardando, preparando, jogando e finalizando.
- [x] Usar `FM_StartFrame` com `get_gametime()` e deadlines absolutos.
- [x] Evitar `set_task` para countdown, inicio de round e infeccao.
- [x] Aguardar jogadores suficientes antes de iniciar o round.
- [x] Iniciar uma contagem curta antes da infeccao.
- [x] Selecionar e lancar o modo atual pelo core.
- [x] Deixar Infection responsavel apenas por escolher/aplicar o primeiro zombie.
- [x] Finalizar o round quando humanos ou zombies vencerem.
- [x] Resetar jogadores para humano no restart sem atraso visual de modelo.
- [x] Expor eventos de prepare, start e end do round.

## Arquitetura e Visual

- [ ] Usar o ReZombie C++ como referencia de modularidade e experiencia visual.
- [ ] Manter o estilo de API elegante do ReZombie C++ para criacao de conteudo.
- [ ] Separar gameplay, runtime, recursos visuais e integracoes.
- [x] Criar HUD e mensagens somente quando ajudarem a validar o fluxo.
- [ ] Evitar globais ocultos, fallbacks silenciosos e codigo acumulado.

## Validacao

- [x] Compilar API e classes iniciais sem erros.
- [x] Compilar APIs modulares e classes sem erros.
- [x] Compilar GameRules inicial sem erros.
- [x] Compilar GameRules e Infection sem erros.
- [x] Validar servidor com ReHLDS, ReGameDLL e ReAPI atualizados.
- [x] Validar carregamento dos plugins ReZombie sem falhas.
- [x] Revisar aviso `GameConfig CRC mismatch` do ambiente AMXX/ReHLDS.
- [x] Validar compilacao automatizada pelo `build.bat`.
- [x] Validar carregamento runtime das APIs, classes, modo e props com smoke temporario.
- [x] Validar entrada de jogador humano.
- [x] Validar troca de classe do jogador.
- [x] Validar infeccao do primeiro zombie.
- [x] Validar fim de round com vitoria zombie.
- [x] Validar fim de round com vitoria humana.
- [x] Validar modelo zombie `rz_source` em runtime.
- [x] Validar subclass zombie `fleshpound` em runtime.
- [x] Validar modelo proprio `rz_fleshpound` da subclass `fleshpound` em runtime.
- [x] Validar comandos do runtime dev em servidor local.
- [x] Validar restart de round sem manter skin zombie antiga.
- [x] Validar fluxo runtime completo pelo `rz_dev_validate_round_flow`.
- [x] Validar itens padrao de humano e zombie em runtime.
- [x] Validar carregamento runtime do feedback visual de round.
