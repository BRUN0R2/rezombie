# TODO

## Agora

- [ ] Validar live que objetivos padrao e buyzones nao aparecem apos restart do servidor local.
- [ ] Validar late join durante `RoundStatePlaying` sem respawn automatico.
- [ ] Trocar validacoes restantes de entidade em `SpawnPoints` para API ReAPI moderna.
- [ ] Adicionar suporte a `default_class` e `override_default_class` em `GameRules` e `ApiGameVars`.
- [ ] Escalar zombies iniciais do modo `Infection` conforme total de jogadores vivos.
- [ ] Implementar infeccao por ataque melee de zombie no modo `Infection`.
- [ ] Evoluir `ApiWeapons` para suportar sons e futuras propriedades melee.
- [ ] Revisar semantica dos forwards para separar restart, prepare e inicio do modo ativo.

## Concluido Recente

- [x] Simplificar `MapObjectives` seguindo a ideia enxuta do Zombie Plague Next com hook moderno ReHLDS.
- [x] Criar `MapObjectives` para neutralizar objetivos padrao, buyzones e C4 do CS.
- [x] Modernizar hooks ReAPI do `GameRules` com enum `GameRulesHookCount`.
- [x] Reescrever `RG_CSGameRules_CheckWinConditions` como gateway oficial das regras do ReZombie.
- [x] Validar que matar o ultimo zombie termina o round com vitoria humana sem `Game Commencing`.
- [x] Criar `rz_dev_fill_bots` para preencher bots em ondas controladas.
- [x] Recriar `PlayerAdmission` com fila e state machine de admissao.
- [x] Estabilizar `PlayerAdmission` para admissao em massa de bots.
- [x] Bloquear `sv_filetransfercompression` para evitar arquivos `.ztmp`.
- [x] Aplicar padrao `ForwardCount` aos forwards internos de `ApiPlayers`.
- [x] Estabilizar admissao automatica apos restart do servidor local.
- [x] Recriar politica explicita de respawn por modo seguindo o fluxo do ReZombie C++.
- [x] Publicar `GameRules` no pre-restart para resetar classes antes do respawn do GameDLL.
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
- [x] Alinhar `EndRoundEvent` com a semantica do ReZombie C++.
- [x] Implementar `GameStateWarmup` como sala de espera antes do `RoundStatePrepare`.
- [x] Exibir countdown de `GameStateWarmup` no HUD.
- [x] Desacoplar inicio do timer global da conclusao da admissao de todos os jogadores.
- [x] Centralizar politicas de respawn e admissao no `GameRules`.
- [x] Fazer `PlayerAdmission` consumir `admission_respawn` do `GameRules`.
- [x] Fazer `ApiPlayers` consumir `respawn_team` do `GameRules`.

## Validacao

- [x] Compilar pacote local com `build.bat`.
- [x] Validar build do preenchimento gradual de bots.
- [x] Validar build da state machine de `PlayerAdmission`.
- [x] Validar admissao de bots sem erro native em `PlayerAdmission`.
- [x] Validar bloqueio de `.ztmp` no runtime.
- [x] Validar build apos aplicar `ForwardCount` em `ApiPlayers`.
- [x] Recarregar ReHLDS via restart do servidor apos copiar o pacote.
- [x] Validar player vivo, CT e humano apos restart do servidor.
- [x] Validar `rz_dev_validate_round_flow fleshpound 4`.
- [x] Validar `rz_dev_validate_round_state`.
- [x] Validar vitoria humana ao matar o ultimo zombie sem `Game Commencing`.
- [x] Aplicar modelos de melee no deploy da faca seguindo a referencia do ReZombie C++.
- [x] Adicionar `world_model` ao contrato inicial de `ApiWeapons`.
- [x] Criar `ApiWeapons` simples com `Weapon:` de melee por classe/subclass, `"view_model"` e `"player_model"`.
