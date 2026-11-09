#Roberto Altavilla - script Skill Lab#

###Esercizio 1###

#Esercizio 1.1
#creo i vettori con i valori indicati
num_clientA <- c(1200,1111,1242,1303,2524,3575,3096)
num_cassA <- c(10,10,10,12,12,18,18)
num_clientB<-c(1407,1038,1729,920,2261,2982,3843)
num_cassB<-c(15,14,14,14,15,15,15)

#Esercizio 1.2
#creo il vettore con i giorni della settimana e poi associo un nome ad ogni elemento dei vettori creati prima
week<-list("Lunedì","Martedì","Mercoledì","Giovedì","Venerdì","Sabato","Domenica")
names(num_clientA)<-  week
names(num_cassA)<-  week
names(num_clientB)<-  week
names(num_cassB)<-  week

#Esercizio 1.3
#metto in confronto la somma dei clienti indicati nel vettore A e vettore B per individuare il maggiore
sum(num_clientA)>sum(num_clientB)

#Esercizio 1.4
#creo il vettore media come somma dei clienti diviso 2
mean_clients<-(num_clientA+num_clientB)/2

#Esercuzui 1.5
#creo un nuovo vettore come somma dei cassieri
tot_cass<-num_cassA+num_cassB
#creo due nuovi vettori come rapporto tra clienti e cassieri
clientVScassA<-num_clientA/num_cassA
clientVScassB<-num_clientB/num_cassB

#Esercizio 1.6
#creo un vettore con la differenza tra i rapporti cliente/cassiere di A e B
A_more_than_B<-clientVScassA - clientVScassB
#creo un vettore buleano per identificare dove A è più grande di B, cioè assume valore positivo
positive_values<- A_more_than_B>0
#creo il vettore soluzione come insime di elementi che hanno valore TRUE nel buleano
soluzione_1.6 <- A_more_than_B[positive_values]

###Esercizio 2###

#Esecizio 2.1
#creo prima i vettori colonna
Numero_Nati_vivi<-c(130471,96579,96936,115495,55069)
Popolazione_iniziale<-c(16130725,11654486,12070842,14167819,6758796)
Popolazione_finale<-c(16138643,11661160,12090637,14149806,6755366)

#assegno nomi alle righe
nome_righe<-c("Regione1","Regione2", "Regione3", "Regione4", "Regione5")
names(Numero_Nati_vivi)<-nome_righe
names(Popolazione_iniziale)<-nome_righe
names(Popolazione_finale)<-nome_righe
print(Popolazione_finale)

#creo un oggetto contenente i 3 vettori colonna creati prima
Regioni<-c(Numero_Nati_vivi, Popolazione_iniziale, Popolazione_finale)
#crei ka natruce
Matrice <- matrix(Regioni, nrow=5, byrow= FALSE, dimnames = list(c("Regione1","Regione2","Regione3","Regione4","Regione5"),c("Numero nati vivi","Popolazione iniziale", "Popolazione finale")))

#Esercizio2.2
#calcolo vettore totale
Totale_nazione<-colSums(Matrice)
#aggiungo la riga in fondo alla matrice
Matrice_completa <- rbind(Matrice, Totale_nazione)

#Esercizio2.3
#calcolo la colonna del tasso di natalità con la formula richiesta
Tasso_natalità <- ((Matrice_completa[,1]/((Matrice_completa[,2]+Matrice_completa[,3])/2))*1000)
#aggiungo l'ultima colonna
Matrice2.3 <- cbind(Matrice_completa, Tasso_natalità)

#Esercizio2.4
#creo un vettore buleano con indicazione dei paesi con natalità maggiore
Natalità_maggiore <- Tasso_natalità>Tasso_natalità[6]
#creo il vettore con la soluzione
soluzione_2.4 <- Tasso_natalità[Natalità_maggiore]

###Esercizio 3###

#Esecizio 3.1
#creo i vettori richiesti
Agriturismo1 <- c("buono", "buono", "sufficiente", "ottimo", "pessimo", "pessimo", "buono", "ottimo", "ottimo", "pessimo")
Agriturismo2 <- c("sufficiente", "sufficiente", "ottimo", "buono", "buono", "pessimo", "ottimo", "buono", "ottimo", "buono")

#Esercizio 3.2
#assegno un valore ai vari giudizi con la funzione factor
Factor_Agriturismo1 <- factor(Agriturismo1,ordered = TRUE,levels = c("pessimo", "sufficiente", "buono", "ottimo"))
Factor_Agriturismo2 <- factor(Agriturismo2,ordered = TRUE, levels = c("pessimo","sufficiente","buono","ottimo"))

#Esercuzio 3.3
#modifico i livelli dei fattori
levels(Factor_Agriturismo1) <- c("P","S","B","O")
levels(Factor_Agriturismo2) <- c("P","S","B","O")

#Esercizio 3.4
#uso la funzione table sui vettori factor dei due agriturismi
Frequenze_Agriturismo1 <- table(Factor_Agriturismo1)
Frequenze_Agriturismo2 <- table(Factor_Agriturismo2)

#Esercizio 3.5
#confronto l'elemento 5 dei due fattori
Factor_Agriturismo1[5]>Factor_Agriturismo2[5]

#Esercizio 3.6
#confronto i valori delle tabelle frequenze per i soli valori B e O
Frequenze_Agriturismo1[3:4]>Frequenze_Agriturismo2[3:4]

###Esercizio 4###

#Esecizio 4.1
#creo i vettori colonna del dataset
Id_stabilimento<-c(1,2,3,4,5,6,7,8,9,10)
Localizzazione<-c("Nord","Nord","Sud","Sud","Centro","Centro","Nord","Sud","Nord","Centro")
Nr_Dipendenti<-c(3725,1165,7042,7819,5879,7285,1599,2154,6354,3295)
Nr_Linee_Produttive<-c(3,2,5,6,4,6,1,2,4,2)
Scalo_Ferroviario<-c(TRUE,FALSE,TRUE,FALSE,TRUE,TRUE,FALSE,FALSE,TRUE,FALSE)
#creo il dataset
ds_alimentare<-data.frame(Id_stabilimento,Localizzazione,Nr_Dipendenti,Nr_Linee_Produttive,Scalo_Ferroviario)

#Esercizio 4.2
#crei le variabili per ciascun gruppo Nord, Centro e Sud
Tot_dipendenti_Nord<-0
Tot_dipendenti_Centro<-0
Tot_dipendenti_Sud<-0
#combito ciclo for e if per sommare nelle variabili precedenti i dipendenti di Nord, Centro e Sud
for(i in Id_stabilimento){
  if(Localizzazione[i]=="Nord"){
    Tot_dipendenti_Nord<-Tot_dipendenti_Nord + Nr_Dipendenti[i]
  } else
    if(Localizzazione[i]=="Centro"){
      Tot_dipendenti_Centro<-Tot_dipendenti_Centro+Nr_Dipendenti[i]
  } else
      Tot_dipendenti_Sud<-Tot_dipendenti_Sud+Nr_Dipendenti[i]
}
#calcolo la media dei dipendenti di Nord, Centro e Sud dividendo le 3 variabili per 10
Media_dipendenti_Nord<-Tot_dipendenti_Nord/10
Media_dipendenti_Centro<-Tot_dipendenti_Centro/10
Media_dipendenti_Sud<-Tot_dipendenti_Sud/10

#Esercizio 4.3
#creo la variabile d'appoggio
Tot_stabilimenti_noScalo<-0
#uso nuovamente il ciclo for con la condizione if sull'indicazione Scalo_Ferroviario False
for(i in Id_stabilimento){
  if(Scalo_Ferroviario[i]==FALSE){
    Tot_stabilimenti_noScalo<-Tot_stabilimenti_noScalo+1
  }
}

#Esercizio 4.4
#creo il vettore dimensione vuoto
Dimensione<-0
#uso il ciclo for e if per aggiungere un elemento al vettore Dimensione come da indicazione
for(i in Id_stabilimento){
  if(Nr_Linee_Produttive[i]<=2){
    Dimensione[i]<-c("PICCOLO")
  }else
    Dimensione[i]<-c("GRANDE")
}

###Esercizio 5###

#Esecizio 5.1
#creo variabile input
numero<-0
#creo la funzione if di verifica
if(numero>0) {
  print("il numero è positivo")
} else if(numero<0){
    print("il numero è negativo")
} else {
    print("il numero è nullo")
  }  

#Esercizio 5.2
#creo variaible d'appoggio
somma<-0
#creo ciclo for sommando i vari numeri
for (i in 1:150){
  somma<-somma + i
}

#Esercizio 5.3
#creo matrice d'appoggio
my_data<-matrix(data=NA,nrow=5,ncol=5)
#uso un doppio ciclo for per identificare le coordinate e scrivere il numero relativo
for(i in 1:5){
  for(j in 1:i){
    my_data[i,j]<-j
  }
}

#Esercizio 5.4
#creo variabile d'appoggio iniziale
numero = 1
#uso ciclo while per stampare i numeri e aggiungo +2 dopo ciascuna stampa per andare al numero dispari successivo
while(numero<90){
    print(numero)
  numero<-numero +2
}

#Esercuzui 5.5
#creo vettore frequenze
Frequenze<-c(10,15,7,12,8,16,18,9,13,15)

#creo la funzione
Funzione_frequenze<-function(Frequenze) {
  #creo vettore frequenze relative numeriche
  relative_numeriche<-Frequenze/sum(Frequenze)
  #creo vettore frequenze relative percentuali
  relative_percentuali<-relative_numeriche *100
  #chiedo la stampa a video dei risultati
  print(relative_numeriche)
  print(relative_percentuali)
}

#lancio la funzione
Funzione_frequenze(Frequenze)

###Esercizio 6###

#Importo il file CSV
impiegati <- read.csv("C:/Users/User/Desktop/Master LUISS/project_executive_master_LUISS_FULL_introR/impiegati.csv",
                  stringsAsFactors = TRUE)
#Visualizzo e studio il dataset
View(impiegati)
dim(impiegati)
head(impiegati)
tail(impiegati)
str(impiegati)
summary(impiegati)

#Esercizio 6.1
#creo le variabili con gli elementi richiesti dall'esercizio

Media <- mean(impiegati$wage, na.rm = TRUE)
Mediana <- median(impiegati$wage, na.rm = TRUE)
Q1 <- quantile(impiegati$wage, 0.25, na.rm = TRUE)
Q3 <- quantile(impiegati$wage, 0.75, na.rm = TRUE)
IQR <- IQR(impiegati$wage, na.rm = TRUE)
Range <- max(impiegati$wage, na.rm = TRUE) - min(impiegati$wage, na.rm = TRUE)
#per la moda creo una table con la variabile wage
Frequenza_wage <- table(impiegati$wage)
#creo la variabile Moda identificando la frequenza maggiore o se sono presenti più  frequenze maggiori
Moda <- Frequenza_wage[Frequenza_wage == max(Frequenza_wage)]

#Esercizio 6.2
#creo una nuova variabile per non modificare il dataset originale
Impiegati_no_NA <- impiegati$wage
#Identifica quando i valori sono NA
Impiegati_no_NA[is.na(Impiegati_no_NA)]
#Sostituisco i valori NA con la variabile Media
Impiegati_no_NA[is.na(Impiegati_no_NA)] <- Media

#Esercizio 6.3
#costruisco le variabili richieste
varianza <- var(impiegati$wage, na.rm = TRUE)
Standard_deviation <- sd(impiegati$wage, na.rm = TRUE)
Coefficiente_di_variazione <- (Standard_deviation / abs(mean(impiegati$wage, na.rm = TRUE)))
#costruisco il vettore richiesto
Vettore_6.3 <- c(varianza,Standard_deviation,Coefficiente_di_variazione)

#Esercizio 6.4
subset_wage_male <- impiegati$wage[impiegati$gender == "male"]
subset_wage_female <- impiegati$wage[impiegati$gender == "female"]

#Esercizio 6.5
boxplot(wage ~ gender, data = impiegati,
        xlab = "Gender",
        ylab = "Wage")

#Esercizio 6.6
#uso la funzione tapply per il calcolo della media
tapply(impiegati$wage,impiegati$gender,FUN = mean,na.rm = TRUE)

#Esercizio 6.7
#install(ggplot2)
library(ggplot2)
#creo un barchart
bc1 <- ggplot(impiegati, aes(gender, wage, fill = gender)) +
  stat_summary(fun = mean, geom = "bar") +
  scale_fill_brewer(palette = "Set2", direction = 1) +
  labs(x = "Gender",
       y = "Average Wage")
