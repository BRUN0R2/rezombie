# TODO

## Agora

- [ ] Recriar politica explicita de respawn por modo.

## Concluido Recente

- [x] Criar `ApiGameVars.sma` com facade publica `get_game_var`.
- [x] Remover referencias ao contrato antigo de rounds.
- [x] Recriar `GameRules` como state machine explicita e dona unica das transicoes.
- [x] Integrar selecao de modo sem deixar `launch_mode` alterar estado de round.
- [x] Validar build local com `build.bat`.
- [x] Estudar a arquitetura do ReZombie C++ como referencia de API e limites.
- [x] Fechar a escrita de estado de round em include interno do core.
- [x] Validar `Mode:` registrado ao sincronizar estado publico de round.
- [x] Remover `chance` da API de modos enquanto nao existe selecao ponderada real.
- [x] Separar helpers compartilhados do runtime dev.
- [x] Recriar `SpawnPoints` com selecao global dinamica por score.
- [x] Ajustar `SpawnPoints` para reservar no pre-spawn e aplicar no post-spawn.
- [x] Validar snapshot real de spawn com 31 bots no servidor local.
- [x] Trocar sync de round para snapshot interno tipado.

## Validacao

- [x] Compilar pacote local com `build.bat`.
- [x] Recarregar ReHLDS via `changelevel` apos copiar o pacote, sem fechar o HLDS.
