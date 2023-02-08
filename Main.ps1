Import-Module .\Function\APIrequeste.psm1
Import-Module .\Function\WorkDate.psm1
Import-Module .\Function\ExportImportfile.psm1
#________________________________________________________________________________________________________________________________________________________
#Définition des Fonctions
#________________________________________________________________________________________________________________________________________________________
#-----Crée un tableau conttenant toutes les dates voulu-----
Function get-tabdate($Mois,$year,$nbraw){
	$tab = @()
	$tab += "date"
	For($i=1;$i -lt $nbraw;$i=$i+1){
		[string]$day=$i
		$date3 = $day+"/"+$Mois+"/"+$year
		$tab += $date3
	}
	return $tab
}

#-----Extrait les prix de la crypto voulu au date voulu et les formate dans un tableau-----
Function get-Price($tabdate,$Dataweb,$datefin,$coin){
	$date = $tabdate[1]
	$tdiff = New-TimeSpan -Start $date -End $datefin
	$tdiff = $tdiff.Days
	$tab = @($coin)
	For($b=1;$b -lt $tdiff+1;$b){
		
		[int]$datedata = $Dataweb.Substring($Dataweb.Indexof("[")+1,$Dataweb.Indexof(",")-$Dataweb.Indexof("[")-4)
		
		[int]$datetab = get-epoch $tabdate[$b]
		
				
			
		if ( $datedata -lt $datetab ){
			$Dataweb = $Dataweb.Substring($Dataweb.Indexof("],")+2,$Dataweb.LastIndexof("]")-$Dataweb.Indexof("],")-1)
				
		}
		else {
			$tab +=  $Dataweb.Substring($Dataweb.Indexof(",")+1,$Dataweb.Indexof("]")-$Dataweb.Indexof(",")-1)
			$Dataweb = $Dataweb.Substring($Dataweb.Indexof("],")+2,$Dataweb.LastIndexof("]")-$Dataweb.Indexof("],")-1)
			$b=$b+1
			
		}
	}
	return $tab
}
#________________________________________________________________________________________________________________________________________________________

#________________________________________________________________________________________________________________________________________________________
#Définition des actions à effectuer en cas d'erreur
#________________________________________________________________________________________________________________________________________________________
trap {
		"error"
		echo "trop de requete veuillez recommencer plus tard" #Retourner un message d'erreur à l'utilisateur
		Read-Host "Appuyez sur ENTREE pour continuer..." #Attente de confirmation utilisateur
		break  #Arréte le script si une erreur est remonté
	}
#________________________________________________________________________________________________________________________________________________________
	
#________________________________________________________________________________________________________________________________________________________
#Création des Variables permanentes
#________________________________________________________________________________________________________________________________________________________
[int]$Mois = Read-Host "Mois?" #Récupération du mois voulu

[int]$year = Read-Host "Année" #Récupération de l'année voulu

$crypto = get-txt ".\listecrypto.txt"#Appel de la fonction pour avoir la liste des cryptos voulu

[int]$nbcolumn = $crypto.count +1 #calcul du nombre de colone nécessaire au tableau

$Mois2=$Mois+1  #Calcule de la date de début et de fin du mois voulu
$datedebut = "1/"+$Mois+"/"+$year
$datefin = "1/"+$Mois2+"/"+$year

$nbreraw = New-TimeSpan -Start $datedebut -End $datefin #Calcul du nombre de ligne necessaire au tableau
[int]$nbraw = $nbreraw.Days +1

$tab = New-Object 'object[,]' $nbraw,$nbcolumn # Création du tableau principal

$tabdate = get-tabdate $Mois $year $nbraw # Appel à la fonction pour récupérer toutes les dates dans un tableau
#________________________________________________________________________________________________________________________________________________________

#________________________________________________________________________________________________________________________________________________________
#Remplissage du tableau principale
#________________________________________________________________________________________________________________________________________________________
#-----Boucle pour ajouter les dates dans le tableau principal-----
$b=0 #Definition d'une variable temporaire
Foreach ($element in $tabdate){
		$tab[$b,0] = $element
		$b=$b+1
	}
clear-variable -name b #Netoyage de la variable temporaire

#-----Remplissage du tableau principal avec les prix colone par colone-----
For($i=0;$i -lt $nbcolumn-1;$i++){ #Remplissage du tableau principal avec les prix colone par colone
	#-----Définition des variables temporaires-----
	$coin = $crypto[$i] #selection du coin
	
	$dataweb = requestweb $coin $datedebut $datefin # Récupération des prix du coin via l'API coingecko
	
	$tabprice = get-Price $tabdate $dataweb $datefin $coin #Formatage des prix du coin dans un tableau simple
	
	$a = $i+1
	$b=0
	
	#-----Boucle pour ajouter les Prix du coin dans le tableau principal-----
	Foreach ($element in $tabprice){
		$tab[$b,0] = $tabdate[$b]
		$tab[$b,$a] = $element
		$b=$b+1
	}
	
	echo $coin" : ok" #Retour utilisateur 
	
	clear-variable -name Dataweb,a,b,coin,tabprice #Netoyage des variables temporaire
	
	start-sleep 2 # Petite pause pour eviter la saturation de l'API coingeco
	
}
#________________________________________________________________________________________________________________________________________________________

#________________________________________________________________________________________________________________________________________________________
#Export du tableau principale en csv
#________________________________________________________________________________________________________________________________________________________
$Path = ".\"+[string]$Mois+"-"+[string]$year+".csv"  #définition du Path pour le csv
Export-csv $tab $nbraw $nbcolumn $Path
#________________________________________________________________________________________________________________________________________________________

