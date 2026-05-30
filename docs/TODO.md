# TODO

## Agora

- [ ] Criar politica explicita de respawn por modo.
- [ ] Criar API publica de respawn quando a politica estiver definida.
- [ ] Criar HUD proprio para selecao de classes.
- [ ] Confirmar visualmente spawn sem armas duplicadas no HUD.
- [ ] Confirmar jogador entrando durante `RoundStatePlaying` sem respawn automatico.

## Concluido Recente

- [x] Fechar a escrita de estado de round em include interno do core.
- [x] Validar `Mode:` registrado ao sincronizar estado publico de round.
- [x] Remover `chance` da API de modos enquanto nao existe selecao ponderada real.
- [x] Separar helpers compartilhados do runtime dev.
- [x] Recriar `SpawnPoints` com selecao global dinamica por score.

## Validacao

- [x] Compilar pacote local com `build.bat`.
- [x] Validar runtime em servidor local ReHLDS apos copiar o pacote.
