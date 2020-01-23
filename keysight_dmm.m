%% 
% Universidade Federal do Rio Grande do Norte
% Centro de Tecnologia
% N�cleo de Pesquisa e Inova��o em Tecnologia da Informa��o
% Laborat�rio de Instrumenta��o e Microeletr�nica @ 302
%
%% 
% Script desenvolvido por: Evandson Dantas e Jos� Tauna�
% 11/dez/2019
% Ultima atualiza��o: 23/jan/2020
% 
% Classe de funcionalidades do *Multimetro Keysight 34470A*
% Inicializa��o do objeto
% k34470a = keysight_dmm;

classdef keysight_dmm
   properties
      % Endere�o IP ou Hostname
      % Valor t�pico (string): K-34470A-08700.local
      host = 'K-34470A-08700.local';
      % Porta de comunica��o via protocolo SCPI.
      % Valor padr�o (inteiro): 5025
      port = 5025;
   end
   properties (Access = private)
     objTCPIP = [];
   end
   methods
      % Captura o nome de host caso seja especificado
      function this = keysight_dmm(val)
        if nargin == 1
            this.host = val;
        end
        % Atualiza o objeto
        this.objTCPIP = tcpip(this.host, this.port, 'InputBufferSize', 50000,'Timeout',30);
      end
      % Consultas
      function retorno = comando(this, comando)
         % Permite realizar um comando SCPI conforme manual de instru��es
         % do dispositivo. Alguns comandos possuem retorno e outros n�o.
         %
         % Comandos com retorno ser�o retornados na forma de string
         % ou na forma num�rica com precis�o "double" conforme resposta do
         % dispositivo
         if(nargin ~=2)
             error('Uma string SCPI era esperada.');
         end
         this.objTCPIP = tcpip(this.host, this.port);
         fopen(this.objTCPIP);
         if contains(comando,'?')
             resposta = query(this.objTCPIP, comando);
             resposta = split(resposta(1:end-1),',');
             if ~isnan(str2double(resposta))
                retorno = str2double(resposta);
             else
                retorno = resposta; 
             end
         else
             fprintf(this.objTCPIP, '%s\n', comando);
         end
         fclose(this.objTCPIP);
         return;
      end
      function erro_msg(this, msg)
         chk_erro = this.comando('SYST:ERR?');
         if (str2double(chk_erro{1}) > 0)
          error('%s\nC�digo: %d\nDetalhes: %s\n',msg,str2double(chk_erro{1}),chk_erro{2}); 
         end
      end
      % Comodidades
      function retorno = lerTela(this)
         % Realiza uma leitura do elemento que se encontra na tela 
         retorno = this.comando('READ?');
      end
      function retorno = versao(this)
         % Retorna as informa��es do dispositivo
         retorno = this.comando('*IDN?');
      end
      function limpar(this)
         % Limpa todos os status do instrumento;
         % Isto esvazia a fila de erros al�m de apagar todos os registros de eventos no dispositivo.
         % Tamb�m cancela todos os comandos anteriores.
         this.comando('*CLS');
      end
      function nplc = lerNPLC(this)
          % Permite ler o valor do NPLC
           nplc = this.comando('VOLT:DC:NPLC?');
      end
      function definirNPLC(this, escala)
         % NPLC Significa "Number of Power Line Cycles"
         % A medi��o da tens�o, corrente e resist�ncia � afetada pelo pelo ru�do CA induzido pela linha de energia.
         % O uso de NPLC de 1 ou mais aumenta o tempo de integra��o do ru�do CA e aumenta a resolu��o e a precis�o da medi��o,
         % entretanto, o trade-off torna a taxa de medi��o mais lentas.
         % Para maior precis�o de medi��o, recomenda-se um NPLC de 100
         % 
         % Para este dispositivo s�o poss�veis os valores: 100, 10, 1, 0.2, 0.06, 0.02, 0.006, 0.002 e 0.001
         %
         % Refer�ncia:
         % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=451>
         if isempty(find(escala==[100 10 1 0.2 0.06 0.02 0.006 0.002 0.001], 1))
            error('Escalas dispon�veis: [100 10 1 0.2 0.06 0.02 0.006 0.002 0.001]');
         end
         this.comando(['VOLT:DC:NPLC ',num2str(escala)]);
         % Verifica se deu erro no comando
         this.erro_msg('N�o foi poss�vel definir o NPLC.');
         % Verifica se conseguiu setar direitinho
         nplc = this.lerNPLC;
         if (nplc ~= escala)
            warning('N�o foi poss�vel definir o NPLC.\nNPLC atual: %.4f\n',nplc); 
         end
      end
      function impedancia = consultarAltaImpedancia(this)
          % Valor l�gico: 0 para 10 Megaohms ou 1 para 1 Teraohms
          if (this.comando('VOLT:IMP:AUTO?') == 0)
             impedancia = 10e6;
          else
            impedancia = Inf;
          end
          % Verifica se deu erro no comando
         this.erro_msg('N�o foi poss�vel consultar a imped�ncia'); 
      end
      function definirAltaImpedancia(this, impedancia)
          % Valor l�gico: 0 para 10 Megaohms ou 1 para 1 Teraohms
          if (impedancia == 0)
            this.comando('VOLT:IMP:AUTO OFF') ;
          else
            this.comando('VOLT:IMP:AUTO ON');
          end
          % Verifica se deu erro no comando
         this.erro_msg('N�o foi poss�vel definir a imped�ncia'); 
      end
      function definirEscalaDC(obj, escala)
         % Escolha entre as escalas para medir n�vel DC
         % Op��es: 0.1, 1, 10, 100 e 1000
         %
         % Refer�ncia: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         if isempty(find(escala==[0.1 1 10 100 1000], 1))
            error('Par�metro inv�lido. Verifique o manual: help keysight_34470a.definirEscalaDC');
         end
         obj.comando(['VOLT:DC:RANG ',num2str(escala)]);
      end
      function retorno = lerEscalaDC(obj)
         % Retorna a escala DC definida
         % Refer�ncia: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         retorno = obj.comando('VOLT:DC:RANG?');
      end
      function definirUnidadeDeTemperatura(obj, unidade)
         % Define a unidade de temperatura utilizada pelo equipamento
         % Op��es: 'C', 'F' ou 'K'
         %
         % Refer�ncia: <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=197>
         if ((~contains('CFK',upper(unidade))) || unidade.length ~= 1)
             error('Par�metro inv�lido. Verifique o manual: help keysight_34470a.definirUnidadeDeTemperatura');
         end
         obj.comando(['UNIT:TEMP ',unidade]);
      end
      function retorno = lerUnidadeDeTemperatura(obj)
         % Retorna a escala DC definida
         % Refer�ncia: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         retorno = obj.comando('UNIT:TEMP?');
      end
      
      function reset(obj)
         % 
         obj.comando('*RST');
      end
      function retorno = autoTeste(obj)
         % Executa o autoteste do instrumento
         % Retorna o n�mero de falhas encontradas durante o teste.
         % Ideal que retorne valor 0.
         % 
         % NOTA: *Todas as ponteras de provas devem estar desconectadas para execu��o desde comando*
         retorno = obj.comando('TEST:ALL?'); 
      end
      function escreverTextoTelaCheia(obj, texto)
         % Coloque um texto em tela cheia
         % Quebra de linha: \n
         % Para sair do comando: limpar
         % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=197>
         obj.comando(['DISP:TEXT "',texto,'"']); 
      end
      function retorno = lerTextoTelaCheia(obj)
         % L� o texto que est� escrito no display
         retorno = obj.comando('DISP:TEXT?'); 
      end
      function apagaTextoTelaCheia(obj)
         % Apaga qualquer texto que tenha sido escrito com o comando escreverTextoTelaCheia
        obj.comando('DISPlay:TEXT:CLEar');
      end
      function modoMedirTensaoDC(this, escala, resolucao)
          % Par�metros opcionais: modoMedirTensaoDC(escala, resolucao)
          if nargin < 2 
              this.comando('CONF:VOLT:DC');
          elseif nargin == 2
              this.comando(['CONF:VOLT:DC ', num2str(escala)]);
          else
              this.comando(['CONF:VOLT:DC ', num2str(escala), ',',num2str(resolucao)]);
          end
      end
      function modoMedirTensaoAC(this, escala, filtro)
         if nargin < 2 
              this.comando('CONF:VOLT:AC');
          elseif (nargin == 2)
              this.comando(['CONF:VOLT:AC ', num2str(escala)]);
         else
              this.comando(['CONF:VOLT:AC ', num2str(escala), ',',num2str(filtro)]);
          end
      end
      function modoMedirResistencia(this, opt)
          % Permite medir resist�ncia utilizando a configura��o de 2 ou 4 fios
          % Para medi��o de resist�ncia utilizando 2 fios:
          %     -> Conecte as pontas de prova nas portas Input Hi e Lo do DMM
          %     -> Conecte as pontas de provas no resistor a ser medido
          %     -> Execute este comando sem passar quaisquer par�metro
          %     -> Mude a escala de medi��o com o comando "definirEscala"
          %     -> [Opcional] Defina demais configura��es como PLC, tempo de amostragem ...
          %     -> Realize a medi��o com o comando "medir"
          % Para medi��o de resist�ncia utilizando 4 fios:
          %     -> Conecte as pontas de prova nas portas Input Hi, Input Lo, Sense Hi e Sense Lo do DMM
          %     -> Conecte as pontas de provas no resistor a ser medido (Input Hi com Sense Hi e Input Lo com Sense Lo).
          %     -> Execute este comando passando o par�metro 4. obj.modoMedirResistencia(4)
          %     -> Mude a escala de medi��o com o comando "definirEscala".
          %     -> [Opcional] Defina demais configura��es como PLC, tempo de amostragem ...
          %     -> Realize a medi��o com o comando "medir"
          % Refer�ncia:
          % https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=243
          if (nargin < 1 || opt == 2)
             this.comando('CONF:RES');
          elseif (opt == 4)
            this.comando('CONF:FRES');
          else
              error('Digite como par�metro a quantidade de pontas de prova utilizadas para a medi��o [2 ou 4]');
          end
      end
      function erro = lerErro(this)
          % Permite ler o comando de erro do dispisitivo.
          % Refer�ncia:
          % https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=461
         erro = this.comando('SYST:ERR?');
      end
      function retorno = naTora(this, cmd)
          fopen(this.objTCPIP);
            fprintf(this.objTCPIP,cmd);
            retorno = fscanf(this.objTCPIP);
        fclose(this.objTCPIP); 
      end
      function [medidas, tempo] = medir(this, n, st)
        if nargin < 2 
           error('Par�metros insuficientes');
        end
        % Interrompe quaisquer a��es anteriores
        this.comando('ABORT')
        % Desliga o autozero
        this.comando('VOLT:ZERO:AUTO OFF');                % Define o valor auto-zero como desligado
        this.erro_msg('N�o foi poss�vel desligar o autozero');   % Verifica erro
        volt_zero = this.comando('VOLT:ZERO:AUTO?');
        if (volt_zero~=0)
            error('N�o foi poss�vel desligar o autozero');
        end
        % Desliga o null stat
        this.comando('VOLT:DC:NULL:STAT OFF')
        % Define o tipo de medi��o
        this.comando('TRIG:SOUR BUS');                      % Configura o dispositivo para medir utilizando ref. pr�pria 
        this.erro_msg('N�o foi poss�vel definir o BUS');    % Erro ao definir o BUS
        % Verifica o NPLC
        stmin = this.comando('SAMP:TIM? MIN');
        if (st<stmin)
            error('O per�odo m�nimo de amostragem � de %.2e para o NPLC e Resolu��o definidos.',stmin);
        end
        % Define a refer�ncia de amostragem
        this.comando('SAMPle:SOUR TIM');                % Indica que a amostragem seguir� o tempo de amostragem e n�o uma refer�ncia instant�nea
        this.erro_msg('N�o foi poss�vel definir a refer�ncia de medi��o tipo Single');    % Erro ao definir o BUS
        samp_sour = this.comando('SAMPle:SOUR?');
        if ~strcmp(samp_sour{1},'TIM')
            error('N�o foi poss�vel definir a refer�ncia de medi��o tipo Single');
        end
        % Define o per�odo de amostragem
        this.comando(['SAMP:TIM ',num2str(st)]);        % Tempo de amostragem (entre cada amostra)
        this.erro_msg('N�o foi poss�vel definir o per�odo de amostragem');    % Verifica erro
        sam_st = this.comando('SAMP:TIM?');
        if (sam_st~=st)
            error('N�o foi poss�vel definir o per�odo de amostragem');
        end
        % Define o n�mero de amostras a serem capturadas
        this.comando(['SAMP:COUN ',num2str(n)]);        % N�mero de amostras a serem capturadas
        this.erro_msg('N�o foi poss�vel definir a quantidade de amostras a serem obtidas');   % Verifica erro
        sam_n = this.comando('SAMP:COUN?');
        if (sam_n~=n)
            error('N�o foi poss�vel definir a quantidade de amostras a serem obtidas');
        end
        % Deixa o dispositivo pronto para medir, esperando o sinal (comando *TRG)
        this.comando('INIT');
        this.erro_msg('Falha ao preparar o dispositivo para esperar o trigger');   % Verifica erro
        % Inicia a medi��o
        this.comando('*TRG');
        this.erro_msg('Falha ao enviar o trigger');   % Verifica erro
        % Espera ao menos capturar 10 medidas
        pause(min(st*10,st*n));
        % Abre a conex�o de forma permanente com um buffer maior
        this.objTCPIP.InputBufferSize = 2^(16+4);
        this.objTCPIP.Timeout = 30;
        %get(this.objTCPIP); % for debug
        fopen(this.objTCPIP);
        % Vari�veis auxiliares
        buff_med = zeros(1,n);
        buff_n = 1;
       
        % Repete at� que n�o tenha mais dados
        while(n > (buff_n-1))
          
          % Requisita os dados
          dados_para_ler = nan;
          while(isnan(dados_para_ler))
            fprintf(this.objTCPIP,'DATA:POINTS?\n');
            dados_para_ler = str2double(fgets(this.objTCPIP));
          end
          
          % Define a quantidade de dados para ler
          n_leitura = min([dados_para_ler 2500]);
          
          % Solicita dados
          fprintf(this.objTCPIP,'R? %d\n',n_leitura);
          
          % L� os dados
          buffer = fgets(this.objTCPIP);
          
          % Captura o comprimento guia
          size_len = str2double(buffer(2));
          
          % Separa os n�meros da string
          buffer = split(buffer((3+size_len):end),',');
          
          % Converte para double
          buffer = str2double(buffer);
          
          % Copia para a sa�da
          buff_med(buff_n:(buff_n+n_leitura-1)) = buffer;
          
          % Incrementa a quantidade de dados lidas
          buff_n = buff_n + n_leitura;
          
          % Captura quantas amostras restantes j� tem
          dados_para_ler = nan;
          while(isnan(dados_para_ler))
            fprintf(this.objTCPIP,'DATA:POINTS?\n');
            dados_para_ler = str2double(fgets(this.objTCPIP));
          end
          
          % Espera por (n-buff_n) amostras ou at� que tenha 100 amostras para ler.
          pause(min([(n-buff_n) 2500])*st);
          
          % Imprime quantos % est� completa
          %fprintf('Medi��o %.4f%%\r',100*(buff_n-1)/n);
          
        end
        
        % Fecha a conex�o
        fclose(this.objTCPIP);

        % Prepara o retorno
        medidas = buff_med;
        tempo = 0:st:(n-1)*st;               % Retorna o tempo
      end
      function fechar(this)
         fclose(this.objTCPIP); 
      end
   end
end
