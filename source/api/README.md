# API

Esta pasta guarda as APIs modulares do projeto.

Cada API deve expor um contrato pequeno, tipado e facil de usar por plugins Pawn.

Exemplo de estilo esperado:

```pawn
new Class:class = checkClassExists("zombie");
new Subclass:subclass = create_subclass("zombie_swarm", class);
new Props:props = get_subclass_var(subclass, "props");

set_props_var(props, "health", 700);
set_props_var(props, "speed", 260);
set_props_var(props, "gravity", 1.0);
```
