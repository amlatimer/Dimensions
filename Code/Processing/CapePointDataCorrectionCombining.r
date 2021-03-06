setwd("C:/Work/Dimensions/Data") # Change this to your local Dimensions/Data directory
#setwd("D:\\Jasper\\Side projects\\Taylor plots\\GitData\\Dimensions\\Data")
#########################################################################
#########################################################################
################### STEP 1: SYNONYM CORRECTIONS  ########################
#########################################################################
#########################################################################

library(gregmisc)
library(xlsx)

## Read in synonym data
syn=read.xlsx("PreprocessedData/MasterSynonymCorrections.xlsx", 1)

# Create speciesID of genus & species names; minor edits (remove issues from NAs, double spaces)
syn$SpeciesID=paste(syn$OldGenus, syn$OldSpecies)
syn$SpeciesID=sub("NA", "", syn$SpeciesID)
syn$SpeciesID=sub("  ", " ", syn$SpeciesID)

head(syn)
syn1=subset(syn, select=c("SpeciesID", "NewGenus", "NewSpecies"))
head(syn1)

## Read in list of seasonally apparent species
seas=read.xlsx("PreprocessedData/MasterSynonymCorrections.xlsx", 2)

#########################################################################
################### Correct synonyms in releve data #####################
#########################################################################

#Read in releve data
new=read.csv("PreprocessedData/ReleveQuadrat2010.csv")
old=read.table("PreprocessedData/capepointALL.txt", header=T)

# Correct from synonym spreadsheet
old=rename.vars(old, from=c("GENUS","SPECIES"), to=c("Genus","Species"))
old$SpeciesID=paste(old$Genus, old$Species)
new$SpeciesID=paste(new$Genus, new$Species)

#Change double spaces to single spaces
old$SpeciesID=sub("  ", " ", old$SpeciesID)
new$SpeciesID=sub("  ", " ", new$SpeciesID)

#Correct one entry with space at beginning of name
new$SpeciesID[new$SpeciesID==" Erica muscosa"]="Erica muscosa"

#Merge releve data with synonyms
old1=merge(old, syn1, by="SpeciesID", all.x=T, all.y=F)
head(old1)
summary(old1)

new1=merge(new, syn1, by="SpeciesID", all.x=T, all.y=F)
head(new1)
summary(new1)

###check to make sure all have been corrected
old1[is.na(old1$NewGenus)==T,]
nrow(old1[is.na(old1$NewGenus)==T,])  #0
new1[is.na(new1$NewGenus)==T,]
nrow(new1[is.na(new1$NewGenus)==T,]) #0

##Exclude seasonally apparent species
old1<-old1[-which(old1[,1]%in%seas[,1]),]
new1<-new1[-which(new1[,1]%in%seas[,1]),]

##Write corrected files
#make folder
dir.create("PostprocessedData")
write.csv(new1, "PostprocessedData/ReleveQuadrat2010_NamesCorrected.csv", row.names=F)
write.csv(old1, "PostprocessedData/Releve66_96_NamesCorrected.csv", row.names=F)

#########################################################################
################### Correct synonyms in (field & lab) trait data ########
#########################################################################

fieldtr=read.csv("PreprocessedData/20110329_FieldData.csv", stringsAsFactors=F)

fieldtr$SpeciesID=paste(fieldtr$Genus, fieldtr$Species)
fieldtr$SpeciesID=sub("  ", " ", fieldtr$SpeciesID)

fieldtr1=merge(fieldtr, syn1, by="SpeciesID", all.x=T, all.y=F)

## "Watsonia sp." in field traits: only one was collected and Cory & Adam didn't know if it was tabularis or meriana
# Because the only difference is in flower color, the measurements are to be used for both species
fieldtr1$NewGenus=as.character(fieldtr1$NewGenus)
fieldtr1$NewSpecies=as.character(fieldtr1$NewSpecies)
fieldtr1$NewGenus[fieldtr1$SpeciesID=="Watsonia "]="Watsonia"
fieldtr1$NewSpecies[fieldtr1$SpeciesID=="Watsonia "]="tabularis" 
#Duplicate Watsonia row
fieldtr1[nrow(fieldtr1)+1,]=fieldtr1[fieldtr1$SpeciesID=="Watsonia ",]
dim(fieldtr1)
fieldtr1$NewSpecies[nrow(fieldtr1)]="meriana"
  
###check to make sure all have been corrected
fieldtr1[is.na(fieldtr1$NewGenus)==T,]
nrow(fieldtr1[is.na(fieldtr1$NewGenus)==T,])  #1

#Exclude one problematic row ("Plot70sp1" was IDed only to family)
fieldtr2=fieldtr1[is.na(fieldtr1$NewGenus)==F,]  
dim(fieldtr2)

###check to make sure all have been corrected
fieldtr2[is.na(fieldtr2$NewGenus)==T,]
nrow(fieldtr2[is.na(fieldtr2$NewGenus)==T,])  #0

##Exclude seasonally apparent species
fieldtr2<-fieldtr2[-which(fieldtr2[,1]%in%seas[,1]),]

##Write corrected file
write.csv(fieldtr2, "PostprocessedData/20110329_FieldData_namescorrected.csv", row.names=F)

#########################################################################
################### Correct synonyms in isotope data ####################
#########################################################################

iso=read.csv("PreprocessedData/isotopes.csv")
head(iso)
dim(iso)

iso1=merge(iso, syn1, by.x="Species", by.y="SpeciesID", all.x=T, all.y=F)
dim(iso1)

###check to make sure all have been corrected
iso1[is.na(iso1$NewGenus)==T,]

iso1$NewGenus=as.character(iso1$NewGenus)
iso1$NewSpecies=as.character(iso1$NewSpecies)

#Exclude one problematic row ("Plot70sp1" was IDed only to family)
iso2=iso1[is.na(iso1$NewGenus)==F,]  
dim(iso2)

##Exclude seasonally apparent species
iso2<-iso2[-which(iso2[,1]%in%seas[,1]),]

write.csv(iso2, "PostprocessedData/isotopes_namescorrected.csv", row.names=F)


#########################################################################
#########################################################################
################### STEP 2: COMBINE RELEVE DATA #########################
#########################################################################
#########################################################################

library(reshape)
library(gregmisc)

#Read in data
new=read.csv("PostprocessedData/ReleveQuadrat2010_namescorrected.csv")
old=read.csv("PostprocessedData/Releve66_96_NamesCorrected.csv")

str(new)

#plot-level metrics for new data
pc=subset(new, select= c("A_PercCov","B_PercCov","C_PercCov","D_PercCov",
        "E_PercCov","F_PercCov","G_PercCov","H_PercCov","I_PercCov","J_PercCov"))
new$MeanPercCov=rowSums(pc, na.rm=T)/10

abun=subset(new, select=c(A_N, B_N, C_N, D_N, E_N, F_N, G_N, H_N, I_N, J_N))
new$TotalAbun=rowSums(abun,na.rm=T)


releve=subset(new, select=c(Plot, NewGenus, NewSpecies, MeanPercCov, TotalAbun))
releve$Year=2010

#reshape old data
mold=melt.data.frame(old, id.vars=c("NewGenus","NewSpecies"), measure.vars=colnames(old)[24:185])

#new columns
mold$Plot=sub("X","",mold$variable)
mold$Plot=sub("[.].*","",mold$Plot)
mold$Plot=as.numeric(mold$Plot)

mold$Year[grepl(".66",mold$variable)==T]=1966
mold$Year[grepl(".66",mold$variable)==F]=1996

summary(mold)

mold=rename.vars(mold, from="value", to="AbunClass")

#merge old & new
releve2=merge(releve,mold,by=c("Year","Plot","NewGenus","NewSpecies"),all=T)

#Reclassify 2010 abundance
releve2$AbunClass[is.na(releve2$AbunClass) & releve2$TotalAbun<=4]=1
releve2$AbunClass[is.na(releve2$AbunClass) & releve2$TotalAbun>=5 & releve2$TotalAbun<=10]=2
releve2$AbunClass[is.na(releve2$AbunClass) & releve2$TotalAbun>=11 & releve2$TotalAbun<=50]=3
releve2$AbunClass[is.na(releve2$AbunClass) & releve2$TotalAbun>=51 & releve2$TotalAbun<=100]=4
releve2$AbunClass[is.na(releve2$AbunClass) & releve2$TotalAbun>=101]=5

releve2=subset(releve2, select=c("Year","Plot","NewGenus","NewSpecies","MeanPercCov","TotalAbun","AbunClass"))

write.csv(releve2, "PostprocessedData/ReleveAll.csv")


#########################################################################
#########################################################################
############# STEP 3: COMBINE TRAIT DATA &  #############################
############# CREATE TRAITS x SPECIES DATAFRAME #########################
#########################################################################
#########################################################################

library(gregmisc)

#################### Lab Data ######################
####################################################

tr=read.csv("PostprocessedData/20110329_FieldData_namescorrected.csv", stringsAsFactors=F)
head(tr)
dim(tr)
str(tr)
labtr=read.csv("PreprocessedData/Cape Point Lab Data.csv", stringsAsFactors=F)
head(labtr)
dim(labtr)
str(labtr)

labtr=rename.vars(labtr, from="ID", to="Replicate")
labtr=rename.vars(labtr, from="LeafArea", to="RawLeafArea_cm2")
labtr=rename.vars(labtr, from="LeafLength", to="LeafLength_cm")
labtr=rename.vars(labtr, from="LeafFresh_g", to="RawLeafFresh_g")
labtr=rename.vars(labtr, from="LeafDry_g", to="RawLeafDry_g")
labtr=rename.vars(labtr, from="AvgLeafWidth", to="AvgLeafWidth_cm")
labtr=rename.vars(labtr, from="MaxLeafWidth", to="MaxLeafWidth_cm")
labtr=rename.vars(labtr, from="LeafThickness", to="LeafThickness_mm")

tr$UID=paste(tr$Date, tr$Sample, tr$Collector)
labtr$UID=paste(labtr$Date, labtr$Sample, labtr$Collector)

alltr=merge(tr, labtr, by="UID", suffixes=c(".x",""), all=T)
head(alltr)
dim(alltr)
colnames(alltr)

#add coordinates
coord=read.csv("PreprocessedData/Taylor_COGHNR.csv")
head(coord)
coord=subset(coord, select=c(PLOT, Latitude..Ross.Turner.2010., Longitude..Ross.Turner.2010.))
coord=rename.vars(coord,from="PLOT", to="plot")
coord=rename.vars(coord, from="Latitude..Ross.Turner.2010.", to="Latitude2010")
coord=rename.vars(coord, from="Longitude..Ross.Turner.2010.", to="Longitude2010")

coord=coord[!is.na(coord$Latitude2010),]


alltr=merge(alltr,coord,by="plot",all.x=T)
dim(alltr)

alltr=subset(alltr, select=c("Collector","GardenField","Date","Sample","Replicate",
  "NewGenus","NewSpecies","plot","VeldAge","Latitude2010","Longitude2010","Height_cm",
  "CanopyX_cm","CanopyY_cm","BranchingOrder","NumLeaves",
  "RawLeafArea_cm2","LeafLength_cm","AvgLeafWidth_cm","MaxLeafWidth_cm","LeafThickness_mm",
  "RawLeafFresh_g","RawLeafDry_g","TwigFresh_g","TwigDry_g","SLA","LeafSucculence","TwigSucculence"))

#Exclude 7 specimens with no lab data
alltr=alltr[!is.na(alltr$Collector),]

dim(alltr)
str(alltr)

#convert from percent
head(alltr$LeafSucculence)
alltr$LeafSucculence=sub("%","",alltr$LeafSucculence)
head(alltr$LeafSucculence)

head(alltr$TwigSucculence)
alltr$TwigSucculence=sub("%","",alltr$TwigSucculence)
head(alltr$TwigSucculence)

#convert to numeric
alltr$RawLeafArea_cm2=as.numeric(alltr$RawLeafArea_cm2)
alltr$AvgLeafWidth_cm=as.numeric(alltr$AvgLeafWidth_cm)
alltr$MaxLeafWidth_cm=as.numeric(alltr$MaxLeafWidth_cm)
alltr$SLA=as.numeric(alltr$SLA)
alltr$LeafSucculence=as.numeric(alltr$LeafSucculence)
alltr$TwigSucculence=as.numeric(alltr$TwigSucculence)

str(alltr)

#divide by number of leaves
alltr$LeafArea_cm2=alltr$RawLeafArea_cm2/alltr$NumLeaves
alltr$LeafFresh_g=alltr$RawLeafFresh_g/alltr$NumLeaves
alltr$LeafDry_g=alltr$RawLeafDry_g/alltr$NumLeaves


summary(alltr)


write.csv(alltr, "PostprocessedData/LabData.csv",row.names=F)

######### Correcting Errors in Lab Data ############
####################################################
labdt=read.csv("PostprocessedData/LabData.csv")
head(labdt)
dim(labdt)

labdt[labdt$AvgLeafWidth_cm==22.0,]
labdt$AvgLeafWidth_cm[labdt$AvgLeafWidth_cm==22.0]=2.2
labdt[labdt$AvgLeafWidth_cm==2.2,]

labdt[labdt$LeafThickness_mm==146,]
labdt$LeafThickness_mm[labdt$LeafThickness_mm==146]=.146
labdt[labdt$LeafThickness_mm==.146,]

labdt[which(labdt$BranchingOrder>4),]
labdt$BranchingOrder[which(labdt$BranchingOrder>4)]=NA
labdt[which(labdt$BranchingOrder>4),]

write.csv(labdt, "PostprocessedData/LabData.csv",row.names=F)
 
########### Traits by Species Dataframe ############
####################################################
## NOTE: If you want to flag & exclude errors, run the errorflags.r script instead of this part

tr=read.csv("PostprocessedData/20110329_FieldData_namescorrected.csv")
head(tr)
dim(tr)
labdt=read.csv("PostprocessedData/LabData.csv")
head(labdt)
dim(labdt)

##Means
means=aggregate(labdt, by=list(labdt$NewGenus, labdt$NewSpecies), mean, na.rm=T)
#warnings--that's ok

summary(means)

means=subset(means, select=c("Group.1","Group.2","NumLeaves",
  "RawLeafArea_cm2","LeafArea_cm2","LeafLength_cm","AvgLeafWidth_cm","MaxLeafWidth_cm","LeafThickness_mm",
  "RawLeafFresh_g","RawLeafDry_g","LeafFresh_g","LeafDry_g","TwigFresh_g","TwigDry_g","SLA","LeafSucculence","TwigSucculence"))

colnames(means)
colnames(means)=paste(colnames(means),"_Mean", sep="")
colnames(means)

means=rename.vars(means, from="Group.1_Mean", to="Genus")
means=rename.vars(means, from="Group.2_Mean", to="Species")
colnames(means)
summary(means)
dim(means)

##Stand Dev
stdev=aggregate(labdt, by=list(labdt$NewGenus, labdt$NewSpecies), sd, na.rm=T)
#warnings--that's ok

summary(stdev)

stdev=subset(stdev, select=c("Group.1","Group.2","NumLeaves",
  "RawLeafArea_cm2","LeafArea_cm2","LeafLength_cm","AvgLeafWidth_cm","MaxLeafWidth_cm","LeafThickness_mm",
  "RawLeafFresh_g","RawLeafDry_g","LeafFresh_g","LeafDry_g","TwigFresh_g","TwigDry_g","SLA","LeafSucculence","TwigSucculence"))

colnames(stdev)
colnames(stdev)=paste(colnames(stdev),"_SD", sep="")
colnames(stdev)

stdev=rename.vars(stdev, from="Group.1_SD", to="Genus")
stdev=rename.vars(stdev, from="Group.2_SD", to="Species")
colnames(stdev)
summary(stdev)
dim(stdev)

##Number
natest=subset(labdt, select=c("NewGenus","NewSpecies","NumLeaves",
  "RawLeafArea_cm2","LeafArea_cm2","LeafLength_cm","AvgLeafWidth_cm","MaxLeafWidth_cm","LeafThickness_mm",
  "RawLeafFresh_g","RawLeafDry_g","LeafFresh_g","LeafDry_g","TwigFresh_g","TwigDry_g","SLA","LeafSucculence","TwigSucculence"))

natest[,3:18]=!is.na(natest[,3:18])
head(natest)
natest[natest=="TRUE"]=1
head(natest)

n=aggregate(natest[,3:18], by=list(natest$NewGenus, natest$NewSpecies), sum)

summary(n)

colnames(n)
colnames(n)=paste(colnames(n),"_N", sep="")
colnames(n)

n=rename.vars(n, from="Group.1_N", to="Genus")
n=rename.vars(n, from="Group.2_N", to="Species")
colnames(n)
summary(n)
dim(n)

##Field Data Maximums
mx=subset(tr, select=c("NewGenus","NewSpecies","Height_cm","CanopyX_cm","CanopyY_cm","BranchingOrder"))
mx=aggregate(mx[3:6], by=list(mx$NewGenus, mx$NewSpecies), max, na.rm=T)
#warnings--that's ok

head(mx)

mx$BranchingOrder[mx$BranchingOrder==-Inf]=NA

colnames(mx)
colnames(mx)=paste(colnames(mx),"_Max", sep="")
colnames(mx)

mx=rename.vars(mx, from="Group.1_Max", to="Genus")
mx=rename.vars(mx, from="Group.2_Max", to="Species")
colnames(mx)
summary(mx)
dim(mx)

##Veg traits
cpall=read.csv("PostprocessedData/Releve66_96_NamesCorrected.csv", header=T)
head(cpall)
dim(cpall)

grw=subset(cpall, select=c("NewGenus","NewSpecies","DISPERSAL","REGENERATION","GROWTHFORM"))

grw=rename.vars(grw, from=c("NewGenus","NewSpecies"), to=c("Genus","Species"))
colnames(grw)
summary(grw)
dim(grw)

##Isotope data
iso=read.csv("PostprocessedData/isotopes_namescorrected.csv")
head(iso)

isomean=aggregate(iso[5:16], by=list(iso$NewGenus, iso$NewSpecies), mean, na.rm=T)

head(isomean)
dim(isomean) 

isomean=rename.vars(isomean, from="Group.1", to="Genus")
isomean=rename.vars(isomean, from="Group.2", to="Species")

##### Combining #####
head(means)
head(stdev)
head(n)
head(mx)
head(grw)
head(isomean)

dim(means)
dim(stdev)
dim(n)
dim(mx)
dim(grw)
dim(isomean)

#There is one extra species in field data
meanscheck=paste(means$Genus, means$Species)
mxcheck=paste(mx$Genus, mx$Species)
mxcheck[mxcheck %in% meanscheck==F]  # Cussonia thyrsiflora; I am just going to exclude this...

#Mismatch between isotope data and lab data
isocheck=paste(isomean$Genus, isomean$Species)
meanscheck[meanscheck %in% isocheck==F]   # Syncarpha canescens, Ficinia filiformis, Ficinia trichodes - in lab data but not isotope data
isocheck[isocheck %in% meanscheck==F]   # Syncarpha gnaphaloides, Ficinia oligantha - in isotope data but not lab data
#Will have to deal with this....

#Duplicates in veg traits
grwcheck=paste(grw$Genus, grw$Species)
grw1=grw[grwcheck %in% meanscheck==T,]
dim(grw1)
grw1check=paste(grw1$Genus, grw1$Species)
length(grw1check)
length(unique(grw1check))
grw1[duplicated(grw1check)==T,]
grw1[grw1$Genus=="Erica" & grw1$Species=="hispidula",]  #ok to remove row with NAs; no conflicts in values
grw1[grw1$Genus=="Ficinia" & grw1$Species=="filiformis",] #no conflicts in values; ok to remove duplicate
grw1[grw1$Genus=="Zygophyllum" & grw1$Species=="spinosum",] # Regeneration value differs between these two, so there is still a conflict
# Remove duplicates
grw2=grw1[duplicated(grw1check)==F,]


allsptr=merge(means, stdev, by=c("Genus","Species"), all=T)
colnames(allsptr)
dim(allsptr)
allsptr=merge(allsptr, n, by=c("Genus","Species"), all=T)
colnames(allsptr)
dim(allsptr)
allsptr=merge(allsptr, mx, by=c("Genus","Species"), all.x=T, all.y=F)
colnames(allsptr)
dim(allsptr)
allsptr=merge(allsptr, isomean, by=c("Genus","Species"), all=T)
colnames(allsptr)
dim(allsptr)
allsptr1=merge(allsptr, grw2, by=c("Genus","Species"), all.x=T)
colnames(allsptr)
dim(allsptr)

write.csv(allsptr, "PostprocessedData/SpeciesTraits.csv",row.names=F)