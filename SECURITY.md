# Segurança — debuga.ai vLLM Engine

## Relato responsável

Não abra uma issue pública para vulnerabilidades que possam expor credenciais, permitir acesso não autorizado ou comprometer ambientes conectados.

Envie o relato para **contato@sperrytecnologia.com.br** com:

- repositório e commit afetado;
- descrição e impacto;
- passos mínimos de reprodução;
- mitigação sugerida, quando disponível.

## Escopo

Este repositório é classificado como **reference deployment**. Exemplos, arquivos `.env.example`, Docker Compose e configurações devem ser tratados como referência e revisados antes de uso em ambientes controlados.

## Segredos

- nunca versione `.env` real;
- use chaves diferentes por ambiente;
- restrinja endpoints de inferência por rede e autenticação;
- rotacione imediatamente qualquer credencial exposta.
