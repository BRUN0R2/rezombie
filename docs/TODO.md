# TODO

## Concluido

- [x] Estudar Zombie Plague Next como referencia de logica AMXPawn simples.
- [x] Estudar ReZombie C++ como referencia de arquitetura, hooks e modernizacao.
- [x] Inicializar o repositorio Git local.
- [x] Criar regras iniciais do projeto.

## Proxima Meta

- [ ] Criar uma base inicial funcional, simples, limpa e enxuta.
- [ ] Manter a primeira versao focada em jogador, round e infeccao.
- [ ] Reimplementar somente o que fizer sentido para este projeto novo.

## Base Inicial

- [ ] Definir a estrutura minima dos modulos em `source`.
- [ ] Criar o nucleo de estado do jogador: humano, zombie, vivo e conectado.
- [ ] Criar a API publica minima em `include/rezombie.inc`.
- [ ] Criar o primeiro modo de jogo: infeccao.
- [ ] Criar o fluxo basico de round: preparar, iniciar, infectar e finalizar.
- [ ] Precachear apenas os recursos usados pela primeira versao.

## Round

- [ ] Usar a logica simples do Zombie Plague Next como referencia principal.
- [ ] Aguardar jogadores suficientes antes de iniciar o round.
- [ ] Iniciar uma contagem curta antes da infeccao.
- [ ] Escolher o primeiro zombie de forma clara e previsivel.
- [ ] Finalizar o round quando humanos ou zombies vencerem.

## Arquitetura e Visual

- [ ] Usar o ReZombie C++ como referencia de modularidade e experiencia visual.
- [ ] Separar gameplay, runtime, recursos visuais e integracoes.
- [ ] Criar HUD e mensagens somente quando ajudarem a validar o fluxo.
- [ ] Evitar globais ocultos, fallbacks silenciosos e codigo acumulado.

## Validacao

- [ ] Validar carregamento sem erros no servidor.
- [ ] Validar entrada de jogador humano.
- [ ] Validar infeccao do primeiro zombie.
- [ ] Validar fim de round para humanos e zombies.
- [ ] Marcar uma etapa como `[x]` somente depois de validar sem bugs conhecidos.
