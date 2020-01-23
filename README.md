# AVISO
Trabalho do nPITI / Laboratório de Instrumentação e Microeletrônica - LIME (302)

- nPITI: https://labs.imd.ufrn.br/labs/nPITI/laboratorios/LIME
- LIME: http://lime.imd.ufrn.br/

Esta biblioteca encontra-se em desenvolvimento e podem ocorrer incosistências. Favor reportar os bugs na guia issues.

ESTA BIBLIOTECA É DISTRIBUIDA DA FORMA QUE ESTÁ E NÃO É FORNECIDO QUAISQUER GARANTIAS SOBRE SUA UTILIZAÇÃO.

# Biblioteca SPCI para o DMM Keysight 34470A
Colocar o arquivo na mesma pasta do código .m;
Chamar a biblioteca com o comando

    k34470a = keysight_dmm('ip ou hostname do dispositivo')

Para ajuda, digitar:
    
    doc keysight_dmm;

### Comandos implementados:

A seguir são exemplificado uma lista de comandos já implementados:

Comando | Descriçao
------------- | -------------
apagaTextoTelaCheia |	Apaga qualquer texto que tenha sido escrito com o comando escreverTextoTelaCheia 
autoTeste |	Executa o autoteste do instrumento 
comando	| Permite realizar um comando SCPI conforme manual de instruções 
consultarAltaImpedancia |	Valor lógico: 0 para 10 Megaohms ou 1 para 1 Teraohms 
definirAltaImpedancia |	Valor lógico: 0 para 10 Megaohms ou 1 para 1 Teraohms 
definirEscalaDC	| Escolha entre as escalas para medir nível DC 
definirNPLC	| NPLC Significa "Number of Power Line Cycles" 
definirUnidadeDeTemperatura | Define a unidade de temperatura utilizada pelo equipamento 
erro_msg |	 
escreverTextoTelaCheia | Coloque um texto em tela cheia 
fechar | 
lerErro	| Permite ler o comando de erro do dispisitivo. 
lerEscalaDC | Retorna a escala DC definida 
lerNPLC | Permite ler o valor do NPLC 
lerTela | Realiza uma leitura do elemento que se encontra na tela 
lerTextoTelaCheia | Lê o texto que está escrito no display 
lerUnidadeDeTemperatura | Retorna a escala DC definida 
limpar | Limpa todos os status do instrumento; 
medir	| Realiza a medição e retorna a quantidade de amostras especificadas 
modoMedirResistencia | Permite medir resistência utilizando a configuração de 2 ou 4 fios 
modoMedirTensaoAC	 |  
modoMedirTensaoDC | Parâmetros opcionais: modoMedirTensaoDC(escala, resolucao) 
naTora |	 
reset	 | 
versao | Retorna as informações do dispositivo 
