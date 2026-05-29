# Informacoes do Projeto

ReZombie e um mod zombie novo para CS 1.6.

As bases estudadas servem apenas como referencia:

- Zombie Plague Next: logica simples de round, infeccao, classes e modos.
- ReZombie C++: visual da API, organizacao, modularidade e experiencia de criacao.

## Direcao da API

- APIs modulares ficam em `source/api`.
- A API deve ser simples, bonita, tipada e facil de manter.
- Criar novas classes, subclasses e modos deve ser muito facil.
- Usar handles tipados como `Class:`, `Subclass:` e `Props:`.
- Manter propriedades por string, como `"props"`, `"health"`, `"speed"` e `"gravity"`.

Exemplo esperado:

```pawn
new Class:class = checkClassExists("zombie");
new Subclass:subclass = create_subclass("zombie_swarm", class);
new Props:props = get_subclass_var(subclass, "props");

set_props_var(props, "health", 700);
set_props_var(props, "speed", 260);
set_props_var(props, "gravity", 1.0);
```
