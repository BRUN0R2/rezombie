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

- APIs modulares ficam em `source/api`.
- A API deve ser simples, bonita, tipada e facil de manter.
- Criar novas classes, subclasses e modos deve ser muito facil.
- Usar handles tipados como `Class:`, `Subclass:`, `Props:`, `Mode:` e `Model:`.
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
- `ApiRounds` expoe o estado publico do round somente com `get_round_var`.
- `ApiRounds` guarda seu estado interno em `RoundApiRuntime`.
- O estado real do round pertence ao `GameRules`.
- A escrita do estado publico do round usa `set_round_runtime_var` em `include/rezombie/core/RoundRuntime.inc`.
- `set_round_runtime_var` e interno e deve rejeitar qualquer escritor que nao seja o `GameRules`.
- O `GameRules` organiza estado interno em `RoundConfig`, `RoundRuntime` e `RoundForwards`.
- A selecao inicial de modos permanece deterministica e escolhe o primeiro modo elegivel.
- Variáveis iniciais de round: `"state"`, `"mode"` e `"time_left"`.
- O tempo configurado do round pertence ao modo via `"round_time"`.
- `time_left` representa somente o tempo ativo sincronizado pelo `GameRules`.
- `GameCvars` e o dono das cvars criticas do jogo.
- `GameCvars` aplica e trava cvars criticas com `hook_cvar_change`.
- `SpawnPoints` e o dono dos spawns jogaveis usados pelo mod.
- `SpawnPoints` combina spawns de CT e TR para permitir humanos em massa antes da infeccao.
- `SpawnPoints` usa anchors do mapa para gerar slots jogaveis validados por hull.
- `SpawnPoints` reserva slots durante burst de respawn para impedir players nascendo juntos.
- `SpawnPoints` escolhe onde nascer, mas nao respawna jogadores.
- `GameRules` respawna explicitamente jogadores conectados no restart do round.
- `mp_freezetime` deve ficar em `0` para o fluxo do mod começar direto.
- O delay de fim de round continua separado do freeze inicial.
- `mp_limitteams`, `mp_autoteambalance` e `mp_autokick` ficam em `0` para o CS padrão não quebrar times, admissao e fluxo de round do mod.
- Cvar critica inexistente deve falhar explicitamente com `set_fail_state`.
- O core de round nao deve acumular responsabilidade de cvars.
- O core deve bloquear fim de round padrao do CS desde `RoundStateFreezing`.
- Antes da infecção, qualquer jogador jogável que nascer deve ser humano/CT.
- Menus padrão de time e personagem do CS ficam bloqueados.
- Jogadores sem time são admitidos pelo core em CT sem depender do menu padrão.
- A admissao controlada finaliza o estado interno de join do CS para evitar cameras de selecao.
- A admissao controlada tambem reseta intro camera, observer vars e view para o proprio jogador.
- Jogadores admitidos antes da infeccao podem receber respawn imediato.
- Durante `RoundStatePlaying` e `RoundStateEnding`, respawn automático fica bloqueado.
- Durante `RoundStatePlaying` e `RoundStateEnding`, jogadores já admitidos não podem trocar de time.
- Durante `RoundStatePlaying` e `RoundStateEnding`, jogador novo pode ser admitido sem respawn automático.
- A API de players só aplica classe, modelo e itens quando o jogador está vivo e em T/CT.
- `ApiPlayers` é o único dono de props, modelo e itens no pós-spawn.
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
```

Exemplo esperado:

```pawn
new Class:class = RequireClass("zombie");
new Model:model = create_model("rz_source");
set_class_var(class, "model", model);

new Subclass:subclass = create_subclass("fleshpound", class);
new Model:subclassModel = create_model("rz_fleshpound");
set_subclass_var(subclass, "model", subclassModel);

new Props:props = get_subclass_var(subclass, "props");

set_props_var(props, "health", 700);
set_props_var(props, "speed", 260);
set_props_var(props, "gravity", 1.0);
```

## Modelos

- `rz_source` e o modelo zombie padrao da primeira base.
- `rz_fleshpound` e o modelo proprio da subclass `fleshpound`.
- Subclasses podem configurar um modelo proprio quando necessario.
- Subclasses sem modelo proprio usam o modelo da classe pai.
- A classe zombie deve configurar modelo de forma explicita.
- A classe humana pode usar o modelo padrao do CS enquanto nao existir modelo humano proprio.

## Ordem de Carregamento

Ordem inicial esperada dos plugins:

1. `rezombie/api/ApiProps.amxx`
2. `rezombie/api/ApiModels.amxx`
3. `rezombie/api/ApiClasses.amxx`
4. `rezombie/api/ApiSubclasses.amxx`
5. `rezombie/api/ApiModes.amxx`
6. `rezombie/api/ApiRounds.amxx`
7. `rezombie/api/ApiPlayers.amxx`
8. Classes em `rezombie/classes`
9. Modos em `rezombie/gamemodes`
10. `rezombie/core/GameCvars.amxx`
11. `rezombie/core/SpawnPoints.amxx`
12. `rezombie/core/GameRules.amxx`
13. HUD em `rezombie/hud`

As APIs devem carregar antes de qualquer classe, modo ou core que use suas natives.
Modulos de HUD devem escutar forwards publicos e nao devem colocar regras dentro do core.
O pacote gerado em `build/cstrike` deve manter os plugins separados por modulo, igual ao `source`.

## Runtime Dev

- `DevRuntime.amxx` e exclusivo para validacao local.
- Helpers compartilhados do runtime dev ficam em `include/rezombie/dev/DevRuntimeSupport.inc`.
- O build gera `plugins-rezombie-dev.ini` separado da lista principal.
- Comandos dev devem ser genericos e explicitos.
- Comandos dev nao devem virar dependencia do gameplay.
- `rz_dev_restart_round` aceita delay opcional para validar restart temporizado.
- Apos copiar `.amxx` novo, usar `changelevel` para recarregar plugins sem fechar o servidor.
- Para validar somente gameplay, usar restart de round.

Comandos iniciais:

```text
rz_dev_add_bots <count>
rz_dev_respawn_player <id>
rz_dev_infect_player <id> <subclass>
rz_dev_change_class <id> <class> [subclass]
rz_dev_validate_player <id>
rz_dev_dump_player <id>
rz_dev_restart_round [delay]
rz_dev_validate_spawn_spacing
rz_dev_validate_round_flow [subclass] [required_players]
rz_dev_validate_forward_returns [player] [subclass]
rz_dev_validate_round_state
```

## HUD

- `RoundFeedback.amxx` fica em `source/hud`.
- O modulo HUD escuta forwards de round e infeccao.
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
- `@round_end(RoundEndReason:reason)`

Callbacks `pre` usam `RZ_CONTINUE` para permitir e `RZ_SUPERCEDE` para bloquear.
