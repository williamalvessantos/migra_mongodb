![enter image description here](https://raw.githubusercontent.com/williamalvessantos/migra_mongodb/master/migration-fish.jpg)

Migração MongoDB
================
## Realiza o export/import com validação em container com o mongoDB ##

**Entendendo a necessidade:**

Recentemente recebi a missão em realizar a migração de um banco de dados MongoDB, é comum essa necessidade de levar dados de um banco para o outro, por diversos motivos, migração de servidores, validação de dados ou snapshot para desenvolvimentos. Não irei abordar os motivos, cada qual possui a sua particularidade.

O método utilizado deveria ser capaz de realizar o processo de forma consistente, e foi escolhido a forma binaria para exportar e importar os dados:

**Exportar base de dados:**

    mongodump -h ds011241.mlab.com:11241 -d p0c -u <user> -p <password> -o <output directory>

**Importar base de dados:**

    mongorestore -h ds011241.mlab.com:11241 -d p0c -u <user> -p <password> <input .bson file> 

Segue o link referente a documentação oficial: https://docs.mongodb.com/

Mesmo assim, seria necessário a execução do processo de forma parametrizada, e um JOB para apoiar assim evitar o retrabalho e transpor essa barreira de forma positiva, criar um arquivo de log que seja possível entender todos os passos e armazenar para inspeção futura.

**Pré requisito:**

Ambiente Linux, Mac OS e derivados, docker instalado na máquina que irá executar esse processo, eu realizei essa POC utilizando um Mac.

Como parte do exercício, foi criado uma base de dados mongoDB no site mLab.com, fornece gratuitamente 500MB para sandbox, e isso é muito mais que suficiente para nosso experimento, e consumindo 29MB de espaço em disco.

![enter image description here](https://raw.githubusercontent.com/williamalvessantos/migra_mongodb/master/Captura%20de%20Tela%202017-12-18%20a%CC%80s%2023.39.20.png)

Optei em utilizar um container para receber os dados, simplificar o processo, conferir e validar os dados, não poderia deixar para depois e ter uma surpresa no futuro. Tudo deve ocorrer conforme a execução esperada. Não é necessário ter o mongoDB instalado na máquina, será utilizado o mongoDB do próprio container.

Esse procedimento possui fins didáticos, e talvez seja necessário ajustar os scripts para sua realidade.

**Então vamos lá, mão na massa:**

Para facilitar a atividade utilizei um arquivo de configuração, dessa forma acredito que fica mais simples e tudo fica mais claro e definido como entrada e saída, segue formato:

**Arquivo:** migra_sample.cfg

    : migra_sample.cfg
    ; Sample configure ;
    ; Caractere ";" comment
    
    [MONGODB_ORIGEN]
    HOST = ds011241.mlab.com  ; host name
    DBNM = p0c		          ; db name
    PORT = 11241              ; mongo port
    USER = mongo_poc          ; dbuser
    PASS = Mongo_123          ; dbpass
    
    [MONGODB_DESTINO]
    HOST = localhost          ; host name
    DBNM = p0c                ; db name
    PORT = 27017              ; mongo port
    USER = admin              ; user
    PASS = admin              ; password
    DUMP = /data/dump/        ; dump directory
    
    ; END FILE. NOT REMOVE THIS COMMENT ;;;

Para rodar é necessário executar o comando, e passar o arquivo de configuração:

**Script:** migra_mongo.sh

    ./migrar_mongo.sh migra_sample.cfg

Após disparo do script todos os passos irão ser explicados em tempo de execução.

Já efetuado o carregamento do arquivo de configuração e declaração dos valores, os próximos passos são:

 - Provisionar um container;  
 - Realizar o dump com o comando sendo executado a partir do container;
 - Realizar o import para o MongoDB do container;
 - Realizar a criação do acessos ao banco.

Tudo deve ter funcionado perfeitamente e liso. Pode realizar a conexão nesta nova base de dados MongoDB.

O projeto pode ser acessado diretamente no link: https://github.com/williamalvessantos/migra_mongodb

Processos sempre poderão ser melhorados, caso tenha uma sugestão entre em contato.
