%% 
% Universidade Federal do Rio Grande do Norte
% Centro de Tecnologia
% Núcleo de Pesquisa e Inovação em Tecnologia da Informação
% Laboratório de Instrumentação e Microeletrônica @ 302
%
%% 
% Script desenvolvido por: Evandson Dantas e José Taunaí
% 11/dez/2019
% Ultima atualização: 23/jan/2020
% 
% Classe de funcionalidades do *Multimetro Keysight 34470A*
% Inicialização do objeto
% k34470a = keysight_dmm;

classdef keysight_dmm
   properties
      % Endereço IP ou Hostname
      % Valor típico (string): K-34470A-08700.local
      host = 'K-34470A-08700.local';
      % Porta de comunicação via protocolo SCPI.
      % Valor padrão (inteiro): 5025
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
         % Permite realizar um comando SCPI conforme manual de instruções
         % do dispositivo. Alguns comandos possuem retorno e outros não.
         %
         % Comandos com retorno serão retornados na forma de string
         % ou na forma numérica com precisão "double" conforme resposta do
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
          error('%s\nCódigo: %d\nDetalhes: %s\n',msg,str2double(chk_erro{1}),chk_erro{2}); 
         end
      end
      % Comodidades
      function retorno = lerTela(this)
         % Realiza uma leitura do elemento que se encontra na tela 
         retorno = this.comando('READ?');
      end
      function retorno = versao(this)
         % Retorna as informações do dispositivo
         retorno = this.comando('*IDN?');
      end
      function limpar(this)
         % Limpa todos os status do instrumento;
         % Isto esvazia a fila de erros além de apagar todos os registros de eventos no dispositivo.
         % Também cancela todos os comandos anteriores.
         this.comando('*CLS');
      end
      function nplc = lerNPLC(this)
          % Permite ler o valor do NPLC
           nplc = this.comando('VOLT:DC:NPLC?');
      end
      function definirNPLC(this, escala)
         % NPLC Significa "Number of Power Line Cycles"
         % A medição da tensão, corrente e resistência é afetada pelo pelo ruído CA induzido pela linha de energia.
         % O uso de NPLC de 1 ou mais aumenta o tempo de integração do ruído CA e aumenta a resolução e a precisão da medição,
         % entretanto, o trade-off torna a taxa de medição mais lentas.
         % Para maior precisão de medição, recomenda-se um NPLC de 100
         % 
         % Para este dispositivo são possíveis os valores: 100, 10, 1, 0.2, 0.06, 0.02, 0.006, 0.002 e 0.001
         %
         % Referência:
         % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=451>
         if isempty(find(escala==[100 10 1 0.2 0.06 0.02 0.006 0.002 0.001], 1))
            error('Escalas disponíveis: [100 10 1 0.2 0.06 0.02 0.006 0.002 0.001]');
         end
         this.comando(['VOLT:DC:NPLC ',num2str(escala)]);
         % Verifica se deu erro no comando
         this.erro_msg('Não foi possível definir o NPLC.');
         % Verifica se conseguiu setar direitinho
         nplc = this.lerNPLC;
         if (nplc ~= escala)
            warning('Não foi possível definir o NPLC.\nNPLC atual: %.4f\n',nplc); 
         end
      end
      function impedancia = consultarAltaImpedancia(this)
          % Valor lógico: 0 para 10 Megaohms ou 1 para 1 Teraohms
          if (this.comando('VOLT:IMP:AUTO?') == 0)
             impedancia = 10e6;
          else
            impedancia = Inf;
          end
          % Verifica se deu erro no comando
         this.erro_msg('Não foi possível consultar a impedância'); 
      end
      function definirAltaImpedancia(this, impedancia)
          % Valor lógico: 0 para 10 Megaohms ou 1 para 1 Teraohms
          if (impedancia == 0)
            this.comando('VOLT:IMP:AUTO OFF') ;
          else
            this.comando('VOLT:IMP:AUTO ON');
          end
          % Verifica se deu erro no comando
         this.erro_msg('Não foi possível definir a impedância'); 
      end
      function definirEscalaDC(obj, escala)
         % Escolha entre as escalas para medir nível DC
         % Opções: 0.1, 1, 10, 100 e 1000
         %
         % Referência: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         if isempty(find(escala==[0.1 1 10 100 1000], 1))
            error('Parâmetro inválido. Verifique o manual: help keysight_34470a.definirEscalaDC');
         end
         obj.comando(['VOLT:DC:RANG ',num2str(escala)]);
      end
      function retorno = lerEscalaDC(obj)
         % Retorna a escala DC definida
         % Referência: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         retorno = obj.comando('VOLT:DC:RANG?');
      end
      function definirUnidadeDeTemperatura(obj, unidade)
         % Define a unidade de temperatura utilizada pelo equipamento
         % Opções: 'C', 'F' ou 'K'
         %
         % Referência: <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=197>
         if ((~contains('CFK',upper(unidade))) || unidade.length ~= 1)
             error('Parâmetro inválido. Verifique o manual: help keysight_34470a.definirUnidadeDeTemperatura');
         end
         obj.comando(['UNIT:TEMP ',unidade]);
      end
      function retorno = lerUnidadeDeTemperatura(obj)
         % Retorna a escala DC definida
         % Referência: % <https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=196>
         retorno = obj.comando('UNIT:TEMP?');
      end
      
      function reset(obj)
         % 
         obj.comando('*RST');
      end
      function retorno = autoTeste(obj)
         % Executa o autoteste do instrumento
         % Retorna o número de falhas encontradas durante o teste.
         % Ideal que retorne valor 0.
         % 
         % NOTA: *Todas as ponteras de provas devem estar desconectadas para execução desde comando*
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
         % Lê o texto que está escrito no display
         retorno = obj.comando('DISP:TEXT?'); 
      end
      function apagaTextoTelaCheia(obj)
         % Apaga qualquer texto que tenha sido escrito com o comando escreverTextoTelaCheia
        obj.comando('DISPlay:TEXT:CLEar');
      end
      function modoMedirTensaoDC(this, escala, resolucao)
          % Parâmetros opcionais: modoMedirTensaoDC(escala, resolucao)
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
          % Permite medir resistência utilizando a configuração de 2 ou 4 fios
          % Para medição de resistência utilizando 2 fios:
          %     -> Conecte as pontas de prova nas portas Input Hi e Lo do DMM
          %     -> Conecte as pontas de provas no resistor a ser medido
          %     -> Execute este comando sem passar quaisquer parâmetro
          %     -> Mude a escala de medição com o comando "definirEscala"
          %     -> [Opcional] Defina demais configurações como PLC, tempo de amostragem ...
          %     -> Realize a medição com o comando "medir"
          % Para medição de resistência utilizando 4 fios:
          %     -> Conecte as pontas de prova nas portas Input Hi, Input Lo, Sense Hi e Sense Lo do DMM
          %     -> Conecte as pontas de provas no resistor a ser medido (Input Hi com Sense Hi e Input Lo com Sense Lo).
          %     -> Execute este comando passando o parâmetro 4. obj.modoMedirResistencia(4)
          %     -> Mude a escala de medição com o comando "definirEscala".
          %     -> [Opcional] Defina demais configurações como PLC, tempo de amostragem ...
          %     -> Realize a medição com o comando "medir"
          % Referência:
          % https://literature.cdn.keysight.com/litweb/pdf/34460-90901.pdf?id=2345839#page=243
          if (nargin < 1 || opt == 2)
             this.comando('CONF:RES');
          elseif (opt == 4)
            this.comando('CONF:FRES');
          else
              error('Digite como parâmetro a quantidade de pontas de prova utilizadas para a medição [2 ou 4]');
          end
      end
      function erro = lerErro(this)
          % Permite ler o comando de erro do dispisitivo.
          % Referência:
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
           error('Parâmetros insuficientes');
        end
        % Interrompe quaisquer ações anteriores
        this.comando('ABORT')
        % Desliga o autozero
        this.comando('VOLT:ZERO:AUTO OFF');                % Define o valor auto-zero como desligado
        this.erro_msg('Não foi possível desligar o autozero');   % Verifica erro
        volt_zero = this.comando('VOLT:ZERO:AUTO?');
        if (volt_zero~=0)
            error('Não foi possível desligar o autozero');
        end
        % Desliga o null stat
        this.comando('VOLT:DC:NULL:STAT OFF')
        % Define o tipo de medição
        this.comando('TRIG:SOUR BUS');                      % Configura o dispositivo para medir utilizando ref. própria 
        this.erro_msg('Não foi possível definir o BUS');    % Erro ao definir o BUS
        % Verifica o NPLC
        stmin = this.comando('SAMP:TIM? MIN');
        if (st<stmin)
            error('O período mínimo de amostragem é de %.2e para o NPLC e Resolução definidos.',stmin);
        end
        % Define a referência de amostragem
        this.comando('SAMPle:SOUR TIM');                % Indica que a amostragem seguirá o tempo de amostragem e não uma referência instantânea
        this.erro_msg('Não foi possível definir a referência de medição tipo Single');    % Erro ao definir o BUS
        samp_sour = this.comando('SAMPle:SOUR?');
        if ~strcmp(samp_sour{1},'TIM')
            error('Não foi possível definir a referência de medição tipo Single');
        end
        % Define o período de amostragem
        this.comando(['SAMP:TIM ',num2str(st)]);        % Tempo de amostragem (entre cada amostra)
        this.erro_msg('Não foi possível definir o período de amostragem');    % Verifica erro
        sam_st = this.comando('SAMP:TIM?');
        if (sam_st~=st)
            error('Não foi possível definir o período de amostragem');
        end
        % Define o número de amostras a serem capturadas
        this.comando(['SAMP:COUN ',num2str(n)]);        % Número de amostras a serem capturadas
        this.erro_msg('Não foi possível definir a quantidade de amostras a serem obtidas');   % Verifica erro
        sam_n = this.comando('SAMP:COUN?');
        if (sam_n~=n)
            error('Não foi possível definir a quantidade de amostras a serem obtidas');
        end
        % Deixa o dispositivo pronto para medir, esperando o sinal (comando *TRG)
        this.comando('INIT');
        this.erro_msg('Falha ao preparar o dispositivo para esperar o trigger');   % Verifica erro
        % Inicia a medição
        this.comando('*TRG');
        this.erro_msg('Falha ao enviar o trigger');   % Verifica erro
        % Espera ao menos capturar 10 medidas
        pause(min(st*10,st*n));
        % Abre a conexão de forma permanente com um buffer maior
        this.objTCPIP.InputBufferSize = 2^(16+4);
        this.objTCPIP.Timeout = 30;
        %get(this.objTCPIP); % for debug
        fopen(this.objTCPIP);
        % Variáveis auxiliares
        buff_med = zeros(1,n);
        buff_n = 1;
       
        % Repete até que não tenha mais dados
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
          
          % Lê os dados
          buffer = fgets(this.objTCPIP);
          
          % Captura o comprimento guia
          size_len = str2double(buffer(2));
          
          % Separa os números da string
          buffer = split(buffer((3+size_len):end),',');
          
          % Converte para double
          buffer = str2double(buffer);
          
          % Copia para a saída
          buff_med(buff_n:(buff_n+n_leitura-1)) = buffer;
          
          % Incrementa a quantidade de dados lidas
          buff_n = buff_n + n_leitura;
          
          % Captura quantas amostras restantes já tem
          dados_para_ler = nan;
          while(isnan(dados_para_ler))
            fprintf(this.objTCPIP,'DATA:POINTS?\n');
            dados_para_ler = str2double(fgets(this.objTCPIP));
          end
          
          % Espera por (n-buff_n) amostras ou até que tenha 100 amostras para ler.
          pause(min([(n-buff_n) 2500])*st);
          
          % Imprime quantos % está completa
          %fprintf('Medição %.4f%%\r',100*(buff_n-1)/n);
          
        end
        
        % Fecha a conexão
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
