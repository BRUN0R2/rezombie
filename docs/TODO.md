# TODO

## Concluido

- [x] Estudar Zombie Plague Next como referencia de logica AMXPawn simples.
- [x] Estudar ReZombie C++ como referencia de arquitetura, hooks e modernizacao.
- [x] Inicializar o repositorio Git local.
- [x] Criar regras iniciais do projeto.
- [x] Criar `source/api` para APIs modulares.
- [x] Validar compilacao inicial da API e classes sem erros.

## Proxima Meta

- [ ] Criar uma base inicial funcional, simples, limpa e enxuta.
- [ ] Manter a primeira versao focada em jogador, round e infeccao.
- [ ] Reimplementar somente o que fizer sentido para este projeto novo.

## Base Inicial

- [x] Definir a estrutura minima dos modulos em `source`.
- [x] Implementar APIs modulares em `source/api`.
- [x] Preparar integracao com ReHLDS, ReGameDLL e ReAPI atualizados.
- [x] Criar o nucleo de estado do jogador: humano, zombie, vivo e conectado.
- [x] Criar a API publica minima em `include/rezombie.inc`.
- [x] Criar handles tipados para `Class:`, `Subclass:`, `Props:` e `Mode:`.
- [x] Criar `new const any:null = 0` como nulo tipado da API.
- [x] Criar `FindClass` e `RequireClass`.
- [x] Organizar natives por categoria no include publico.
- [x] Documentar natives em ingles no padrao AMXX/CS 1.6.
- [x] Criar `get_class_var` e `set_class_var`.
- [x] Criar `get_subclass_var` e `set_subclass_var`.
- [x] Criar `get_props_var` e `set_props_var`.
- [x] Criar `get_player_class` e `get_player_subclass`.
- [x] Criar `change_player_class`.
- [x] Criar `infect_player`.
- [x] Criar o primeiro modo de jogo: infeccao.
- [x] Criar o fluxo basico de round: preparar, iniciar, infectar e finalizar.
- [ ] Precachear apenas os recursos usados pela primeira versao.

## Round

- [x] Usar a logica simples do Zombie Plague Next como referencia principal.
- [x] Aguardar jogadores suficientes antes de iniciar o round.
- [x] Iniciar uma contagem curta antes da infeccao.
- [x] Escolher o primeiro zombie de forma clara e previsivel.
- [x] Finalizar o round quando humanos ou zombies vencerem.

## Arquitetura e Visual

- [ ] Usar o ReZombie C++ como referencia de modularidade e experiencia visual.
- [ ] Manter o estilo de API elegante do ReZombie C++ para criacao de conteudo.
- [ ] Separar gameplay, runtime, recursos visuais e integracoes.
- [ ] Criar HUD e mensagens somente quando ajudarem a validar o fluxo.
- [ ] Evitar globais ocultos, fallbacks silenciosos e codigo acumulado.

## Validacao

- [x] Compilar API e classes iniciais sem erros.
- [x] Compilar modo Infection sem erros.
- [ ] Validar servidor com ReHLDS, ReGameDLL e ReAPI atualizados.
- [ ] Validar carregamento sem erros no servidor.
- [ ] Validar entrada de jogador humano.
- [ ] Validar troca de classe do jogador.
- [ ] Validar infeccao do primeiro zombie.
- [ ] Validar fim de round para humanos e zombies.
