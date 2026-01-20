#Rscript a.R

# instalar pacotes
pacotes <- c("stringr", "RODBC", "DBI", "dplyr", "yaml")

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
library(dplyr)
library(yaml) #utilizar config para segurança

#----- QUERY SQL ----

if (exists("queryVendas")) {
  rm(queryVendas)
  print("Dataframe queryVendas removido\n")
} 

# Atribuir query dos descritivos de vendas
queryVendas <- readLines("i:\\projetos\\Consultoria\\ClienteX\\scripts\\Vendas.sql", warn = FALSE)
queryVendas <- paste(queryVendas, collapse = "\n")

print("Query de vendas Adquirida\n")

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
  cat("Conexao falhou\n")
} else { 
  cat("Conexao realizada!\n")
  
  # transformar consulta em dataframe
  dfVendas <- sqlQuery(conn, queryVendas, as.is = TRUE)
  
  print("Dataframe criado\n")
  
  # fechando a conexão
  odbcClose(conn)  
}

#----- TRATAMENTO BASICO ----

# Colunas de valores - para trocar . por ,
col_valores <- c("comRepres1", "comRepres2", "ComVend", "qte", "pr_cad", "pr_venda","TPVenda","frete","pr_custo","TPCusto")

# Trocando . por ,
dfVendas[col_valores] <- lapply(dfVendas[col_valores], function(x) {
  str_replace_all(x, fixed("."), ",")
})

# Quando for devolução, marcar quantidade como negativa
dfVendas <- dfVendas %>%
  mutate(qte = case_when(
    Marca == 'D' & !grepl("^-", qte) ~ paste0("-", qte),
    Marca == 'D' & grepl("^-", qte) ~ qte,
    TRUE ~ qte
  ))

print("Dataframe tratado\n")

write.csv2(dfVendas, file="i:\\projetos\\Consultoria\\ClienteX\\output\\VendasUnpivot.csv")

print("Arquivo VendasUnpivot.csv gravado com sucesso\n")

