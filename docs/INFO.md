# Informacoes do Projeto

ReZombie e um mod zombie novo para CS 1.6.

## Ambiente Alvo

- Usar ReHLDS nas versoes mais recentes.
- Usar ReGameDLL nas versoes mais recentes.
- Usar ReAPI nas versoes mais recentes.
- Priorizar ambiente moderno baseado em ReHLDS, ReGameDLL e ReAPI.
- Evitar depender de comportamento legado do HLDS original quando existir alternativa moderna.

## Validacao do Ambiente

- Ambiente runtime atual validado com ReHLDS `3.15.0.896-dev`.
- ReGameDLL atual validado como `5.30.0.814-dev`.
- ReAPI atual validado como `5.29.0.359-dev`.
- AMX Mod X atual validado como `1.10.0.5476`.
- O aviso `GameConfig CRC mismatch` vem do gamedata CRC-aware do AMXX.
- Esse aviso nao indica falha do ReZombie quando todos os modulos e plugins carregam corretamente.
- Nao editar gamedata padrao do AMXX para esconder esse aviso.
- Usar `data/gamedata/custom` somente se surgir uma falha real de gamedata.

As bases estudadas servem apenas como referencia:

- Zombie Plague Next: logica simples de round, infeccao, classes e modos.
- ReZombie C++: visual da API, organizacao, modularidade e experiencia de criacao.

## Direcao da API

- APIs modulares ficam em `src/api`.
- A API deve ser simples, bonita, tipada e facil de manter.
- Criar novas classes, subclasses e modos deve ser muito facil.
- Usar handles tipados como `Class:`, `Subclass:`, `Props:`, `Mode:` e `Model:`.
- Usar `Weapon:` para o contrato simples de armas por classe e subclass.
- Manter propriedades por string, como `"props"`, `"health"`, `"speed"` e `"gravity"`.
- Usar `RequireClass` quando uma classe for obrigatoria.
- Usar `FindClass` apenas para buscas opcionais.
- Agrupar natives por categoria no include publico.
- Manter natives de zombie junto da categoria Zombie.
- Manter natives de humano junto da categoria Human.
- `get_player_var` expõe apenas estado real do jogador.
- `set_player_var` deve usar o fluxo oficial para aplicar classe/subclasse.
- `connected`, `alive` e `zombie` são variáveis de jogador somente leitura.
- Troca de classe aplica props, modelo, time e itens padrão.
- `ApiGameVars` expoe o estado publico do jogo somente com `get_game_var`.
- `ApiGameVars` guarda seu estado interno em `GameVarsRuntime`.
- O estado real de jogo e round pertence ao `GameRules`.
- A escrita do estado publico usa `sync_game_vars` em `include/rezombie/core/GameVars.inc`.
- `sync_game_vars` publica um snapshot tipado e deve rejeitar qualquer escritor que nao seja o `GameRules`.
- O `GameRules` organiza estado interno em `GameRulesRuntime` e forwards explicitos.
- O `GameRules` organiza hooks ReAPI internos com enum `GameRulesHookCount`.
- O `GameRules` bloqueia `RG_CSGameRules_CheckWinConditions` para impedir `Game Commencing` e vitorias padrao do CS.
- `RG_CSGameRules_CheckWinConditions` funciona apenas como gatilho para `EvaluateRoundWinConditions`.
- Toda decisao de vitoria do round deve passar por `EvaluateRoundWinConditions`.
- `GameStateWarmup` representa a sala de espera antes da contagem real do round.
- `RoundStatePrepare` representa a contagem real antes do modo ativo.
- O tempo padrao inicial segue a referencia do ReZombie C++: 40 segundos de warmup e 20 segundos de prepare.
- O timer de `GameRules` deve usar participantes conectados como gatilho de fluxo, nao esperar todos terminarem a admissao.
- `PlayerAdmission` processa cada jogador em paralelo ao timer global, sem bloquear warmup ou prepare.
- `get_game_var("admission_respawn")` informa se jogadores admitidos podem receber respawn automatico.
- `get_game_var("respawn_team")` informa qual time deve ser aplicado no proximo spawn.
- `get_game_var("human_wins")` e `get_game_var("zombie_wins")` expõem placar direto para diagnostico e HUD.
- O `GameRules` e o dono das politicas de admissao e respawn.
- Grupos internos de forwards devem usar enum com item `Count` como tamanho do array, como `GameRulesForwardCount`.
- Handles de forward em array devem ser inicializados por loop com o valor invalido do modulo.
- Quando a criacao do grupo for pequena e direta, manter o loop de inicializacao dentro de `Create*Forwards` em vez de criar um `Reset*Forwards` separado sem responsabilidade real.
- Quando a destruicao de forwards ou hooks em array for pequena e usada apenas em `plugin_end`, manter o loop de destruicao direto no `plugin_end`.
- O retorno bruto de `ExecuteForward` deve usar nome semantico, como `forwardResult`, em vez de `result`.
- A selecao inicial de modos permanece deterministica e escolhe o primeiro modo elegivel.
- Variaveis iniciais de jogo: `"game_state"`, `"round_state"`, `"mode"`, `"timer"`, `"team_wins"`, `"human_wins"`, `"zombie_wins"`, `"admission_respawn"` e `"respawn_team"`.
- O tempo configurado do round pertence ao modo via `"round_time"`.
- `timer` representa somente o tempo visivel sincronizado pelo `GameRules`.
- `GameCvars` e o dono das cvars criticas do jogo.
- `GameCvars` aplica e trava cvars criticas com `hook_cvar_change`.
- `MapObjectives` e o dono da neutralizacao de objetivos padrao do mapa.
- `MapObjectives` segue a ideia `useless_entities` do ReZombie C++ e Zombie Plague Next, adicionando `func_buyzone` porque o ReZombie tera menu de compras proprio.
- `MapObjectives` usa `RH_GetEntityInit` para vetar entidades cedo, sem varredura pos-spawn.
- `MapObjectives` bloqueia `RG_CSGameRules_CheckMapConditions` e `RG_CSGameRules_GiveC4` para manter objetivos padrao do CS inertes.
- Zonas de compra nativas nao fazem parte do fluxo do ReZombie.
- `SpawnPoints` e o dono dos spawns jogaveis usados pelo mod.
- `SpawnPoints` combina spawns de CT e TR para permitir humanos em massa antes da infeccao.
- `SpawnPoints` cataloga spawns nativos e slots expandidos validados por hull.
- `SpawnPoints` agrupa slots por cluster para distribuir respawns entre regioes do mapa.
- `SpawnPoints` escolhe o melhor slot global por score de distancia, cluster, uso recente e reservas.
- `SpawnPoints` prefere spawn nativo quando ele satisfaz a distancia dinamica atual.
- `SpawnPoints` relaxa distancia minima em etapas quando o mapa nao oferece espaco ideal.
- `SpawnPoints` reserva slots durante burst de respawn para impedir players nascendo juntos.
- `SpawnPoints` escolhe onde nascer, mas nao respawna jogadores.
- `GameRules` reinicia o round quando `RoundStateTerminate` expira.
- `mp_freezetime` deve ficar em `0` para o fluxo do mod começar direto.
- O delay de fim de round continua separado do freeze inicial.
- `mp_limitteams`, `mp_autoteambalance` e `mp_autokick` ficam em `0` para o CS padrão não quebrar times, admissao e fluxo de round do mod.
- `sv_filetransfercompression` fica em `0` para impedir cache `.ztmp` gerado por downloads do servidor.
- Cvar critica inexistente deve falhar explicitamente com `set_fail_state`.
- O core de round nao deve acumular responsabilidade de cvars.
- `PlayerAdmission` e o dono da admissao automatica, bloqueio de menus padrao e reset de camera de join.
- O core deve manter o fluxo proprio de round desde `RoundStateNone`.
- Antes da infecção, qualquer jogador jogável que nascer deve ser humano/CT.
- Menus padrão de time e personagem do CS ficam bloqueados.
- Jogadores sem time são admitidos pelo core em CT sem depender do menu padrão.
- `PlayerAdmission` usa fila e state machine por jogador para processar admissao de forma gradual.
- Hooks de menu e join apenas enfileiram admissao; a aplicacao real acontece no pump controlado do modulo.
- A admissao controlada finaliza o estado interno de join do CS para evitar cameras de selecao.
- A admissao controlada tambem reseta intro camera, observer vars e view para o proprio jogador.
- `PlayerAdmission` só acessa member vars quando o ReAPI reconhece a entidade do jogador como valida.
- `PlayerAdmission` nao aplica reset de camera/view em bots ou HLTV.
- Jogadores admitidos antes da infeccao podem receber respawn imediato.
- A politica `respawn` do modo define a equipe aplicada em spawns durante `GameStatePlaying` + `RoundStatePlaying`.
- Fora do round ativo, todo spawn jogavel volta para humano/CT.
- `Respawn_ToZombiesTeam` deve ser usado por modos onde mortos retornam como zombies durante o round.
- Durante `RoundStatePlaying` e `RoundStateTerminate`, respawn automatico fica bloqueado.
- Durante `RoundStatePlaying` e `RoundStateTerminate`, jogadores ja admitidos nao podem trocar de time.
- Durante `RoundStatePlaying` e `RoundStateTerminate`, jogador novo pode ser admitido sem respawn automatico.
- A API de players só aplica classe, modelo e itens quando o jogador está vivo e em T/CT.
- `ApiPlayers` é o único dono de props, modelo e itens no pós-spawn.
- O runtime interno de jogador (`connected`, `alive`, `zombie`, `class`, `subclass`) pertence ao `ApiPlayers` e nao deve ficar em include compartilhado.
- `ApiPlayers` bloqueia a entrega padrão de itens do GameDLL e entrega apenas itens próprios do ReZombie.
- Seleção futura de classes deve usar HUD próprio do ReZombie.

## Tags e Tipagem

- Usar tags Pawn para todos os handles publicos.
- Evitar `0` solto para representar handle invalido.
- Usar um nulo tipado no estilo ReZombie C++:

```pawn
new const any:null = 0;
```

- Tags iniciais esperadas:

```pawn
Class:
Subclass:
Props:
Mode:
Model:
RespawnType:
```

Exemplo esperado:

```pawn
new Class:class = RequireClass("zombie");
new ModelsPack:models = get_class_var(class, "models");
models_pack_add_model(models, create_model("models/player/rz_source/rz_source.mdl"));

new Subclass:subclass = create_subclass("fleshpound", class);
new Model:subclassModel = create_model("models/player/rz_fleshpound/rz_fleshpound.mdl");
set_subclass_var(subclass, "model", subclassModel);

new Props:props = get_subclass_var(subclass, "props");
new Weapon:melee = get_subclass_var(subclass, "melee");
set_weapon_var(melee, "view_model", create_model("models/player/rz_fleshpound/hand.mdl"));

set_props_var(props, "health", 700);
set_props_var(props, "speed", 260);
set_props_var(props, "gravity", 1.0);
```

## Modelos

- `rz_source` e o modelo zombie padrao da primeira base.
- `rz_fleshpound` e o modelo proprio da subclass `fleshpound`.
- `create_model` recebe caminho completo do `.mdl`, como no ReZombie C++.
- O handle opcional de `create_model` deve ser usado apenas quando o model precisar ser buscado por handle.
- Classes usam `"models"` com `ModelsPack`, como no ReZombie C++.
- Classes usam `"melee"` com `Weapon:` para configurar a faca padrao da classe.
- Subclasses usam `"melee"` com `Weapon:` para sobrescrever a faca padrao da classe.
- Subclasses podem usar `"model"` para sobrescrever o modelo da classe.
- `models_pack_add_model` adiciona um `Model:` ao pack de modelos da classe.
- `set_model_var` altera somente `"body"` e `"skin"`.
- `"handle"`, `"path"` e `"precache_id"` sao propriedades somente leitura.
- Subclasses podem configurar modelos proprios quando necessario.
- Subclasses sem modelo proprio usam o modelo da classe pai.
- Quando uma subclass esta ativa, o melee dela substitui o melee da classe pai, como no ReZombie C++.
- O `view_model` e o `player_model` da melee sao aplicados no deploy da faca.
- O `world_model` fica registrado na `Weapon:` para uso futuro no fluxo de drop/entidade no mundo.
- A classe zombie deve configurar modelo de forma explicita.
- O `Weapon:` inicial expõe `"handle"`, `"view_model"`, `"player_model"` e `"world_model"`.
- `set_weapon_var(melee, "view_model", create_model(...))` define o modelo em primeira pessoa da faca.
- A classe humana pode usar o modelo padrao do CS enquanto nao existir modelo humano proprio.

## Ordem de Carregamento

Ordem inicial esperada dos plugins:

1. `rezombie/api/ApiProps.amxx`
2. `rezombie/api/ApiModels.amxx`
3. `rezombie/api/ApiWeapons.amxx`
4. `rezombie/api/ApiClasses.amxx`
5. `rezombie/api/ApiSubclasses.amxx`
6. `rezombie/api/ApiModes.amxx`
7. `rezombie/api/ApiGameVars.amxx`
8. `rezombie/api/ApiPlayers.amxx`
9. Classes em `rezombie/classes`
10. Modos em `rezombie/gamemodes`
11. `rezombie/core/GameCvars.amxx`
12. `rezombie/core/MapObjectives.amxx`
13. `rezombie/core/SpawnPoints.amxx`
14. `rezombie/core/PlayerAdmission.amxx`
15. `rezombie/core/GameRules.amxx`
16. HUD em `rezombie/hud`

As APIs devem carregar antes de qualquer classe, modo ou core que use suas natives.
Modulos de HUD devem escutar forwards publicos e nao devem colocar regras dentro do core.
O pacote gerado em `build/cstrike` deve manter os plugins separados por modulo, igual ao `src`.

## Runtime Dev

- `DevRuntime.amxx` e exclusivo para validacao local.
- Helpers compartilhados do runtime dev ficam em `include/rezombie/dev/RuntimeSupport.inc`.
- O build gera `plugins-rezombie-dev.ini` separado da lista principal.
- `DevRuntime.amxx` deve carregar com `debug` por padrao na lista dev.
- Comandos dev devem ser genericos e explicitos.
- Comandos dev nao devem virar dependencia do gameplay.
- A IA/Codex pode copiar o pacote gerado em `build/cstrike` para a pasta `cstrike` do servidor local quando for necessario validar runtime.
- Servidor local de validacao: `D:\ARQUIVOS IMPORTANTES\REPOSITORIOS\CS 1.6\REHLDS-Rezombie`.
- Script de inicializacao do servidor local: `D:\ARQUIVOS IMPORTANTES\REPOSITORIOS\CS 1.6\REHLDS-Rezombie\start.bat`.
- A IA/Codex pode parar, iniciar ou reiniciar o servidor local quando isso for necessario para validar alteracoes.
- Para recarregar plugins `.amxx` atualizados, preferir restart do servidor; e mais rapido e mais previsivel do que depender de reload parcial.
- `rz_dev_fill_bots` preenche bots em ondas pequenas para validar carga sem burst artificial.
- `rz_dev_restart_round` aceita delay opcional para validar restart temporizado.
- Para validar somente gameplay, usar restart de round.

Comandos iniciais:

```text
rz_dev_add_bots <count>
rz_dev_fill_bots <target_bots>
rz_dev_respawn_player <id>
rz_dev_kill_player <id>
rz_dev_kill_first_zombie
rz_dev_infect_player <id> <subclass>
rz_dev_change_class <id> <class> [subclass]
rz_dev_validate_player <id>
rz_dev_dump_player <id>
rz_dev_restart_round [delay]
rz_dev_validate_spawn_spacing
rz_dev_validate_round_flow [subclass] [required_players]
rz_dev_validate_forward_returns [player] [subclass]
rz_dev_validate_round_state
rz_dev_dump_game_vars
```

## HUD

- `RoundFeedback.amxx` fica em `src/hud`.
- O modulo HUD escuta forwards de round e infeccao.
- O HUD exibe countdown separado para `GameStateWarmup` e `RoundStatePrepare`.
- O core de round nao deve depender de HUD, chat ou mensagens.
- Countdown HUD usa `FM_StartFrame` com `get_gametime()`.
- Nao usar `set_task` para feedback de countdown.

## Forward Callbacks

- `@change_class_pre(id, Class:class, Subclass:subclass)`
- `@change_class_post(id, Class:class, Subclass:subclass)`
- `@infect_player_pre(id, attacker, Subclass:subclass)`
- `@infect_player_post(id, attacker, Subclass:subclass)`
- `@round_prepare(Mode:mode, Float:duration)`
- `@round_start(Mode:mode, Float:duration)`
- `@round_end(EndRoundEvent:event)`

Callbacks `pre` usam `RZ_CONTINUE` para permitir e `RZ_SUPERCEDE` para bloquear.
