# TODO

## Agora

- [x] Validar live que objetivos padrao e buyzones nao aparecem apos restart do servidor local.
- [x] Validar late join durante `RoundStatePlaying` sem respawn automatico.
- [ ] Trocar validacoes restantes de entidade em `SpawnPoints` para API ReAPI moderna.
- [x] Adicionar suporte a `default_class` e `override_default_class` em `GameRules` e `ApiGameVars`.
- [x] Escalar zombies iniciais do modo `Infection` conforme total de jogadores vivos.
- [x] Implementar infeccao por ataque melee de zombie no modo `Infection`.
- [ ] Evoluir `ApiWeapons` para suportar sons e futuras propriedades melee.
- [ ] Revisar semantica dos forwards para separar restart, prepare e inicio do modo ativo.

## Simplificacao e Crescimento

- [x] Centralizar resolucao de classe, subclass, props, modelo, melee, time e defaults no runtime de players.
- [x] Adicionar accessors internos tipados para propriedades criticas, mantendo propriedades por string somente na API publica.
- [ ] Criar helpers internos pequenos para storage, handles, indices e validacao das APIs sem criar um registry universal generico.
- [ ] Evoluir o contrato de modos com callbacks de ciclo de vida, elegibilidade, respawn, classes padrao e condicoes de vitoria.
- [ ] Dividir `SpawnPoints` internamente em catalogo, geometria, selecao e reservas sem criar novos plugins.
- [ ] Dividir `DevRuntime` por dominio de validacao: jogadores, round, spawn e forwards.
- [ ] Organizar uma matriz curta de validacao para build, round flow, late join, rollback, spawn spacing, infeccao e modos inelegiveis.

## Roadmap de Arquitetura

### Etapa 1 - Limpeza e Infraestrutura

- [x] Trocar o uso indiscriminado de `#include <rezombie>` por includes minimos nas APIs e modulos internos.
- [x] Manter o include agregado `<rezombie>` como interface conveniente para classes, modos e extensoes externas.
- [x] Criar fonte unica de metadados para versao e autor dos plugins.
- [x] Substituir as listas duplicadas do `build.bat` por um manifesto unico de plugins com categoria, fonte, destino, ambiente e ordem de carregamento.
- [x] Gerar `plugins-rezombie.ini` e `plugins-rezombie-dev.ini` a partir do mesmo manifesto usado na compilacao.
- [x] Remover codigo morto, hooks vazios, enums e helpers sem uso, incluindo `OnPlayerKilledPost`, `CountPlayablePlayers` e `IsValidModeHandle`.
- [x] Corrigir `IsHuman` para exigir classe humana valida em vez de assumir que todo jogador nao zombie e humano.
- [x] Atualizar documentacao e exemplos que ainda descrevem assinaturas ou propriedades antigas.

### Etapa 2 - Transicoes Atomicas de Estado

- [x] Reorganizar transicoes do `GameRules` para montar e validar o proximo snapshot antes de alterar o estado publico.
- [x] Publicar `GameVars` antes de emitir forwards de mudanca de game state, round state, timer e modo.
- [x] Garantir que listeners de forwards sempre leiam um snapshot publico coerente.
- [x] Tornar `ChangePlayerClass` transacional para impedir props, modelo, time ou itens parcialmente aplicados.
- [x] Definir rollback completo ou separar validacao e commit para que falhas ocorram antes de mutar o jogador.
- [x] Adicionar validacoes dev para confirmar consistencia de `GameVars` dentro dos forwards.
- [x] Adicionar validacoes dev para confirmar rollback completo quando uma aplicacao de classe falhar.

### Etapa 3 - Decompor o Runtime de Jogadores

- [x] Manter `ApiPlayers` focado no estado publico do jogador e nas operacoes oficiais de classe e infeccao.
- [x] Centralizar resolucao e aplicacao de props e modelos no plugin dono do runtime de players.
- [x] Centralizar entrega e troca de itens no plugin dono do runtime de players.
- [x] Centralizar a decisao de classe e time no spawn no plugin dono do runtime de players.
- [x] Centralizar traducao e sincronizacao de `ScoreInfo` no plugin dono do runtime de players.
- [x] Evitar criar dependencias desnecessarias entre plugins; manter implementacao privada no `.sma` dono.
- [x] Criar um unico resolvedor de runtime para classe, subclass, props, modelo e melee.
- [x] Remover validacoes duplicadas entre `ValidatePlayerClassRuntime` e as funcoes que aplicam o runtime.
- [ ] Revisar os forwards `@change_class_pre` e `@change_class_post` para expor subclass e motivo/origem da troca.

### Etapa 4 - Heranca e Resolucao de Classes

- [x] Definir formalmente a heranca de propriedades entre classe e subclass.
- [x] Permitir que uma subclass sobrescreva somente os valores configurados e herde os demais da classe pai.
- [x] Impedir que uma melee vazia de subclass substitua silenciosamente a melee valida da classe.
- [x] Definir fallback de modelo da subclass para o pack de modelos da classe.
- [ ] Separar handles internos automaticos de classe e subclass para evitar colisoes de `Props`, `Weapon` e `ModelsPack`.
- [ ] Usar nomes internos explicitos como `class:<handle>:props` e `subclass:<handle>:props`.
- [x] Separar classe selecionada pelo jogador, classe padrao global, override do modo e classe atualmente aplicada.
- [x] Definir precedencia de classe como override do modo, selecao do jogador e padrao global.
- [x] Implementar `default_class` e `override_default_class` usando essa resolucao centralizada.

### Etapa 5 - Evoluir o Contrato de Modos

- [x] Remover o fallback que seleciona o primeiro modo quando nenhum modo registrado atende `min_players`.
- [x] Manter o jogo em espera quando nao existir modo elegivel para a quantidade atual de participantes.
- [x] Garantir que o callback de inicio do modo enxergue `RoundStatePlaying` e o snapshot ativo correto.
- [ ] Separar registro do modo, elegibilidade, prepare, inicio, verificacao de vitoria e encerramento.
- [ ] Permitir que modos implementem condicoes de vitoria proprias sem alterar diretamente `GameRules`.
- [ ] Definir callbacks opcionais de ciclo de vida do modo com defaults simples fornecidos pelo core.
- [ ] Permitir politicas de respawn, classes padrao e classes obrigatorias especificas por modo.
- [ ] Preservar `GameRules` como dono das transicoes, timer e encerramento, sem concentrar regras especificas de gameplay.
- [ ] Preparar o contrato para modos baseados em objetivos, sobrevivencia e multiplas equipes logicas.

### Etapa 6 - Reduzir Duplicacao nas APIs

- [ ] Extrair somente os mecanismos comuns e estaveis de storage, handle, indice e validacao das APIs.
- [ ] Evitar um registry universal excessivamente generico ou dificil de depurar em Pawn.
- [ ] Centralizar conversoes repetidas entre handle e indice.
- [ ] Centralizar validacao de handles registrados sem depender de getters publicos por string.
- [ ] Adicionar accessors internos tipados como `GetModeRoundTime`, `GetClassProps` e `GetSubclassParentClass`.
- [ ] Manter propriedades por string na fronteira publica, mas resolver internamente por enums ou helpers especificos.
- [ ] Reduzir duplicacao nos ciclos de inicializacao, validacao e destruicao de hooks ReAPI.
- [ ] Reduzir duplicacao na criacao, validacao, execucao e destruicao de forwards.

### Etapa 8 - Validacao e Escalabilidade

- [ ] Criar uma matriz de validacao para transicoes de round, join, spawn, troca de classe, infeccao e encerramento.
- [ ] Adicionar cenarios dev para modos inelegiveis, falha no launch, rollback de classe e late join.
- [ ] Validar heranca parcial de props, modelo e melee em subclasses.
- [ ] Validar conflitos de handles entre recursos gerados automaticamente.
- [ ] Validar multiplos modos registrados com diferentes requisitos de jogadores.
- [x] Adicionar verificacao automatica de compilacao para todos os plugins do manifesto.
- [ ] Considerar CI depois que o build deixar de depender de listas manuais e caminhos locais rigidos.

## Concluido Recente

- [x] Separar resolucao de classe/subclass/defaults do commit transacional de runtime.
- [x] Adicionar accessors internos tipados para modos, classes, subclasses, props, modelos e melee.
- [x] Implementar heranca parcial de props da subclass com fallback para a classe pai.
- [x] Adicionar `default_class` e `override_default_class` ao contrato de modos e `GameVars`.
- [x] Remover fallback de selecao de modo e manter o round em espera quando nenhum modo atende `min_players`.
- [x] Evoluir `Infection` com escala de zombies iniciais e infeccao por ataque melee baseada na referencia C++.
- [x] Criar `rz_dev_validate_infection_melee` para validar armadura e conversao por ataque melee.
- [x] Separar primeiro zombie e zombies ajudantes na logica do modo `Infection`.
- [x] Simplificar `Infection` para seguir a referencia: launch escolhe zombies iniciais e melee infecta pela classe zombie padrao.
- [x] Simplificar selecao de zombies iniciais em um unico loop, seguindo a referencia do ReZombie C++.
- [x] Manter implementacao privada de players no plugin `ApiPlayers.sma` e `.inc` apenas para contratos e helpers compartilhados.
- [x] Reagrupar `ApiPlayers.sma` como plugin completo, sem includes privados gigantes.
- [x] Organizar internamente runtime de classe, loadout, spawn policy, scoreboard e tipos privados.
- [x] Preservar um unico `ApiPlayers.amxx` como dono do estado e dos hooks de jogador.
- [x] Tornar troca de classe transacional com plano validado antes dos efeitos de engine.
- [x] Restaurar estado interno, time, props, modelo, armas, municao e arma ativa quando o commit de classe falhar.
- [x] Registrar o modelo aplicado no runtime do jogador para permitir restauracao exata.
- [x] Criar falha controlada restrita ao `DevRuntime` para validar rollback apos props e modelo ja terem sido aplicados.
- [x] Centralizar commit de snapshot do `GameRules` antes dos forwards publicos.
- [x] Validar em runtime que prepare, inicio do modo, timer e mudancas de estado observam `GameVars` coerentes.
- [x] Fazer o launch do modo enxergar `RoundStatePlaying` sem permitir check de vitoria durante a inicializacao.
- [x] Criar `plugins.manifest` como fonte unica de compilacao, categoria, ambiente e ordem de carregamento.
- [x] Reduzir includes internos e centralizar versao e autor dos plugins.
- [x] Traduzir o indice de time do `ScoreInfo` para manter a contagem do placar alinhada com `TeamInfo`.
- [x] Reforcar validacoes de `Props` na fonte antes de aplicar runtime de jogador.
- [x] Tornar troca de classe mais robusta com validacao de runtime e rollback de estado interno.
- [x] Validar inicializacao de storages, hooks e forwards criticos dos modulos.
- [x] Substituir fluxo antigo por `PlayerJoining` usando `rg_join_team` como fluxo principal.
- [x] Remover politica publica de respawn de join e deixar a ReGameDLL concluir o joining.
- [x] Mover `register_plugin` de `plugin_precache` para `plugin_init` quando o precache era apenas registro.
- [x] Simplificar `MapObjectives` seguindo a ideia enxuta do Zombie Plague Next com hook moderno ReHLDS.
- [x] Criar `MapObjectives` para neutralizar objetivos padrao, buyzones e C4 do CS.
- [x] Modernizar hooks ReAPI do `GameRules` com enum `GameRulesHookCount`.
- [x] Reescrever `RG_CSGameRules_CheckWinConditions` como gateway oficial das regras do ReZombie.
- [x] Validar que matar o ultimo zombie termina o round com vitoria humana sem `Game Commencing`.
- [x] Criar `rz_dev_fill_bots` para preencher bots em ondas controladas.
- [x] Recriar fluxo inicial de join automatico de jogadores.
- [x] Estabilizar join automatico para entrada em massa de bots.
- [x] Bloquear `sv_filetransfercompression` para evitar arquivos `.ztmp`.
- [x] Aplicar padrao `ForwardCount` aos forwards internos de `ApiPlayers`.
- [x] Estabilizar joining automatico apos restart do servidor local.
- [x] Recriar politica explicita de respawn por modo seguindo o fluxo do ReZombie C++.
- [x] Publicar `GameRules` no pre-restart para resetar classes antes do respawn do GameDLL.
- [x] Criar `ApiGameVars.sma` com facade publica `get_game_var`.
- [x] Remover referencias ao contrato antigo de rounds.
- [x] Recriar `GameRules` como state machine explicita e dona unica das transicoes.
- [x] Integrar selecao de modo sem deixar `launch_mode` alterar estado de round.
- [x] Validar build local com `build.bat`.
- [x] Estudar a arquitetura do ReZombie C++ como referencia de API e limites.
- [x] Fechar a escrita de estado de round no plugin dono do core.
- [x] Validar `Mode:` registrado ao sincronizar estado publico de round.
- [x] Remover `chance` da API de modos enquanto nao existe selecao ponderada real.
- [x] Separar helpers compartilhados do runtime dev.
- [x] Recriar `SpawnPoints` com selecao global dinamica por score.
- [x] Ajustar `SpawnPoints` para reservar no pre-spawn e aplicar no post-spawn.
- [x] Validar snapshot real de spawn com 31 bots no servidor local.
- [x] Trocar sync de round para snapshot interno tipado.
- [x] Alinhar `EndRoundEvent` com a semantica do ReZombie C++.
- [x] Implementar `GameStateWarmup` como sala de espera antes do `RoundStatePrepare`.
- [x] Exibir countdown de `GameStateWarmup` no HUD.
- [x] Desacoplar inicio do timer global da conclusao do joining de todos os jogadores.
- [x] Centralizar politicas de respawn e joining no `GameRules`.
- [x] Fazer `PlayerJoining` respeitar o fluxo `SHOWTEAMSELECT -> GETINTOGAME -> JOINED` da ReGameDLL.
- [x] Fazer `ApiPlayers` consumir `respawn_team` do `GameRules`.

## Validacao

- [x] Validar compilacao sem modulos internos `.sma` incluidos.
- [x] Validar os 19 plugins apos decompor internamente `ApiPlayers`.
- [x] Revalidar rollback durante warmup e `RoundStatePlaying` apos modularizacao.
- [x] Validar rollback de humano para zombie durante warmup apos falha controlada depois da aplicacao do modelo.
- [x] Validar rollback de humano para zombie durante `RoundStatePlaying` sem alterar contagem de humanos/zombies.
- [x] Validar restauracao de classe, subclass, estado zombie, time, props, body, skin, loadout, municao e arma ativa.
- [x] Validar player e round apos rollback transacional.
- [x] Compilar os 19 plugins declarados no manifesto sem erros ou warnings.
- [x] Validar carregamento dos 19 plugins ReZombie no servidor local.
- [x] Validar snapshot publico durante `RoundStatePrepare` e `RoundStatePlaying`.
- [x] Validar primeiro zombie criado apos o modo receber o snapshot ativo.
- [x] Validar escala do modo `Infection` com 32 vivos gerando 4 zombies iniciais e 28 humanos.
- [x] Validar infeccao melee: armadura absorve primeiro e hit seguinte sem armadura converte o humano.
- [x] Validar `rz_dev_validate_infection_melee`.
- [x] Compilar pacote local com `build.bat`.
- [x] Revalidar `build.bat` usando `plugins.manifest` e abrir o servidor local com o pacote gerado.
- [x] Validar build do preenchimento gradual de bots.
- [x] Validar build do fluxo de `PlayerJoining`.
- [x] Validar join de bots sem erro native em `PlayerJoining`.
- [x] Validar bloqueio de `.ztmp` no runtime.
- [x] Validar build apos aplicar `ForwardCount` em `ApiPlayers`.
- [x] Remover duplicacao da resolucao interna de props em `ApiPlayers` preservando o visual publico da API.
- [x] Centralizar constantes e aplicadores internos de props, modelos e debug em `ApiPlayers` sem alterar a API publica.
- [x] Recarregar ReHLDS via restart do servidor apos copiar o pacote.
- [x] Validar player vivo, CT e humano apos restart do servidor.
- [x] Validar `rz_dev_validate_round_flow fleshpound 4`.
- [x] Validar `rz_dev_validate_round_state`.
- [x] Validar vitoria humana ao matar o ultimo zombie sem `Game Commencing`.
- [x] Aplicar modelos de melee no deploy da faca seguindo a referencia do ReZombie C++.
- [x] Adicionar `world_model` ao contrato inicial de `ApiWeapons`.
- [x] Criar `ApiWeapons` simples com `Weapon:` de melee por classe/subclass, `"view_model"` e `"player_model"`.
