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

1. `ApiProps.amxx`
2. `ApiModels.amxx`
3. `ApiClasses.amxx`
4. `ApiSubclasses.amxx`
5. `ApiModes.amxx`
6. `ApiPlayers.amxx`
7. Classes em `source/classes`
8. Modos em `source/gamemodes`
9. Core de round em `source/core`

As APIs devem carregar antes de qualquer classe, modo ou core que use suas natives.

## Runtime Dev

- `DevRuntime.amxx` e exclusivo para validacao local.
- O build gera `plugins-rezombie-dev.ini` separado da lista principal.
- Comandos dev devem ser genericos e explicitos.
- Comandos dev nao devem virar dependencia do gameplay.
- `rz_dev_restart_round` aceita delay opcional para validar restart temporizado.

Comandos iniciais:

```text
rz_dev_add_bots <count>
rz_dev_respawn_player <id>
rz_dev_infect_player <id> <subclass>
rz_dev_change_class <id> <class> [subclass]
rz_dev_validate_player <id>
rz_dev_dump_player <id>
rz_dev_restart_round [delay]
rz_dev_validate_round_flow [subclass] [required_players]
rz_dev_validate_forward_returns [player] [subclass]
```

## Forward Callbacks

- `@change_class_pre(id, Class:class, Subclass:subclass)`
- `@change_class_post(id, Class:class, Subclass:subclass)`
- `@infect_player_pre(id, attacker, Subclass:subclass)`
- `@infect_player_post(id, attacker, Subclass:subclass)`
- `@round_prepare(Mode:mode, Float:duration)`
- `@round_start(Mode:mode, Float:duration)`
- `@round_end(RoundEndReason:reason)`

Callbacks `pre` usam `RZ_CONTINUE` para permitir e `RZ_SUPERCEDE` para bloquear.
