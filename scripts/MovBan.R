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
if (exists("queryMovBan")) {
  rm(queryMovban)
  print("Dataframe queryMovban removido")
} 

queryMovBan <- readLines("i:\\projetos\\Consultoria\\ClienteX\\scripts\\MovBan.sql", warn = FALSE)
queryMovBan <- paste(queryMovBan, collapse = "\n")

print("Query de Movimento Bancario Adquirida")

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
  dfMovBan <- sqlQuery(conn, queryMovBan, as.is = TRUE)
  
  print("Dataframe criado")
  
  # fechando a conexão
  odbcClose(conn)  
}

#----- TRATAMENTO BASICO ----

# Colunas de valores - para trocar . por ,
col_valores <- c("valor")

# Trocando . por ,
dfMovBan[col_valores] <- lapply(dfMovBan[col_valores], function(x) {
  str_replace_all(x, fixed("."), ",")
})

print("Dataframe MovBan tratado")

write.csv2(dfMovBan, file="i:\\projetos\\Consultoria\\ClienteX\\output\\MovBan.csv")

print("Arquivo MovBan.csv gravado com sucesso")