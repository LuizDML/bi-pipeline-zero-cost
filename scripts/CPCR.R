#Rscript a.R

# instalar pacotes
pacotes <- c("stringr", "RODBC", "DBI", "yaml")

if(sum(as.numeric(!pacotes %in% installed.packages())) != 0){
  instalador <- pacotes[!pacotes %in% installed.packages()]
  for(i in 1:length(instalador)) {
    install.packages(instalador, repos = "http://cran.us.r-project.org", dependencies = T)
    break()}
  sapply(pacotes, require, character = T) 
} else {
  sapply(pacotes, require, character = T) 
}

# carregar pacotes
library(RODBC) # conexao com banco
library(DBI) # resultado de consulta SQL como df
library(stringr) # tratar . e , 
library(yaml)

#----- QUERY SQL ----
if (exists("queryCPCR")) {
  rm(queryCPCR)
  print("Dataframe queryCPCR removido")
} 

queryCPCR <- readLines("i:\\projetos\\Consultoria\\ClienteX\\scripts\\CPeCR.sql", warn = FALSE)
queryCPCR <- paste(queryCPCR, collapse = "\n")

print("Query de Contas a Pagar e receber Adquirida")

#----- CONEXAO -----

# carregar arquivo de configuração
config <- yaml::read_yaml("config/config.yml")

# string de conexão
connection_string <- paste0("driver={SQL Server};
	server=", config$database$server,";
	database=", config$database$database,";
	uid=", config$database$uid,";
	pwd=", config$database$pwd,";")

# abrindo a conexão
conn <- odbcDriverConnect(connection_string)

if (is.null(conn)) {
  cat("Conexao falhou")
} else { 
  cat("Conexao realizada!")
  
  # transformar consulta em dataframe
  dfCPCR <- sqlQuery(conn, queryCPCR, as.is = TRUE)
  
  print("Dataframe criado")
  
  # fechando a conexão
  odbcClose(conn)  
}

#----- TRATAMENTO BASICO ----

# Colunas de valores - para trocar . por ,
col_valores <- c("Valor", "ValorEfetivado", "ValorCorrigido")

# Trocando . por ,
dfCPCR[col_valores] <- lapply(dfCPCR[col_valores], function(x) {
  str_replace_all(x, fixed("."), ",")
})

print("Dataframe CPeCR tratado")

write.csv2(dfCPCR, file="i:\\projetos\\Consultoria\\ClienteX\\output\\CPeCR.csv")

print("Arquivo CPeCR.csv gravado com sucesso")