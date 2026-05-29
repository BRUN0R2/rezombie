# Informacoes do Projeto

ReZombie e um mod zombie novo para CS 1.6.

## Ambiente Alvo

- Usar ReHLDS nas versoes mais recentes.
- Usar ReGameDLL nas versoes mais recentes.
- Usar ReAPI nas versoes mais recentes.
- Priorizar ambiente moderno baseado em ReHLDS, ReGameDLL e ReAPI.
- Evitar depender de comportamento legado do HLDS original quando existir alternativa moderna.

As bases estudadas servem apenas como referencia:

- Zombie Plague Next: logica simples de round, infeccao, classes e modos.
- ReZombie C++: visual da API, organizacao, modularidade e experiencia de criacao.

## Direcao da API

- APIs modulares ficam em `source/api`.
- A API deve ser simples, bonita, tipada e facil de manter.
- Criar novas classes, subclasses e modos deve ser muito facil.
- Usar handles tipados como `Class:`, `Subclass:` e `Props:`.
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
```

Exemplo esperado:

```pawn
new Class:class = RequireClass("zombie");
new Subclass:subclass = create_subclass("zombie_swarm", class);
new Props:props = get_subclass_var(subclass, "props");

set_props_var(props, "health", 700);
set_props_var(props, "speed", 260);
set_props_var(props, "gravity", 1.0);
```

## Ordem de Carregamento

Ordem inicial esperada dos plugins:

1. `ApiProps.amxx`
2. `ApiClasses.amxx`
3. `ApiSubclasses.amxx`
4. `ApiModes.amxx`
5. `ApiPlayers.amxx`
6. Classes em `source/classes`
7. Modos em `source/gamemodes`
8. Core de round em `source/core`

As APIs devem carregar antes de qualquer classe, modo ou core que use suas natives.
