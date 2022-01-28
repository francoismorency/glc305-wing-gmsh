//load data coordinate for airfoil (231 points)
Include "glc305-coordinate.geo";
Geometry.Tolerance = 0.1e-8;
Geometry.MatchMeshTolerance = 1e-10;
Geometry.AutoCoherence=0;

//Fonction coord permettant de créer la liste des coordonnées des points
//il y a 231 points dans le fichier coordonnée
Function coord_xy
	For i In {1:231}
		coord[]=Point{i};
		x[i-1]=coord[0];
		y[i-1]=coord[1];
	EndFor
Return

//Fonction left_wing permettant de créer un profil en profondeur

Function left_wing
	ct=0;
    //il y a deux sections une a la racine de l'aile,
    //une autre a l'extrémité
	step_y=demi_span/(nb_sec-1);
    //définir un taille par défaut pour le maillage de surface
    //trois regions: leading edge x<0.1, milieu 0.1<x<0.95, trailing edge x>0.95
    //nous gardons la même taille partout
    taille=le;
	For j In {1:nb_sec-1}
		ct=ct+step_y;
		For i In {0:230}
			p=newp;
			If (x[i]<=0.1)
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
			If (x[i]>0.1 && x[i]<0.95 )
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
			If (x[i]>=0.95 )
				Point(p)={x[i],y[i],-ct,taille};
			EndIf
		EndFor
	EndFor
Return

//Fonction Translate_sec permettant de translater les différents sections de l'ailes pour créer l'aigle en flèche
//avec les 28° par rapport au bord d'attaque.

Function Translate_sec
//section à la racine points de 1 à 231
//section à l'extrémité points de 232 à 462
	x_translate= demi_span/(nb_sec-1)*Tan(sweep);
	For j In {1:nb_sec-1}
		For i In {(231*j)+1:(231*j)+231}
			Translate {x_translate*j,0,0}{Point{i};}
		EndFor
	EndFor		
Return			

//Fonction coord_ch_quart permettant de faire la rotation des sections selon le quart de leur chord pour créer le 
// twist de -4° de l'aile

Function coord_ch_quart
	step_z=demi_span/(nb_sec-1);
	step_angle=(twist_angle)/(nb_sec-1);
	For j In {1:nb_sec-1}
		tt[]=Point{(231*j)+1};
		ttt[]=Point{(231*j)+231};
		ycar=ttt[1]-tt[1];
		xcar=ttt[0]-tt[0];
        //l'angle de twist est réparti linéairement
        //l'angle de twist est de 0 deg à la racine
        //l'angle de twist est de 4 deg à l'extrémité
		angg=Atan(ycar/xcar);
        //la rotation se fait par rapport au quart de la corde
        // posx, posy coordonnées du quart de la corde
		posy=0.25*(1-rt*j)*root_ch*Sin(angg);
		posx=0.25*(1-rt*j)*root_ch*Cos(angg);
		For i In {(231*j)+1:(231*j)+231}
				Rotate {{0,0, 1},{posx,posy,tt[2]},step_angle*j} {Point{i};}
		EndFor
	EndFor
Return

//Fonction scale permettant de mettre à l'echelle chaque sectionde l'aile

Function scale
	step_z=demi_span/(nb_sec-1);
    //la mise à l'échelle de la corde d'épend de l'effilement 
    // et de la position le long de l'envergure 
	rt=(1-taper_ratio)/(nb_sec-1);
	For j In {1:nb_sec-1}
		tt[]=Point{(231*j)+1};
		For i In {(231*j)+1:(231*j)+231}
			Dilate {{tt[0],tt[1],tt[2]},(1-rt*j)*root_ch}{Point{i};}
		EndFor
	EndFor
Return

//Fin des fonctions

//
//Code principal aile GLC305 
//
//configuration de la moitié d'une aile GLC 305
//grandeurs physiques de l'aile données en pouce et converties en pieds
demi_span=60*0.0254; //la moitié de l'envergure
root_ch=25.2*0.0254; //la chord à la racine en inch
nb_sec=2; //le nombre de section de l'aile voulu
sweep=28*Pi/180.; //l'angle de la flèche
taper_ratio=0.4; //le ratio entre la longueur de la chord du bout d'aile divisé par celle des la racine
twist_angle=4*Pi/180; //l'angle de rotation de l'aile
//
// info pour le maillage lié à la géométrie
// définir une grandeur et une grandeur d'élément caractéristique
lcar=root_ch;
le=lcar/50;
ld=3*lcar;


//Creation de l'aile 


Call coord_xy;
Call left_wing;

Call scale;
xpt1[]=Point{1};
Dilate {{xpt1[0], xpt1[1], xpt1[2]},root_ch}{Point{1:231};} //mettre à l'échelle la première section d'aile
Call coord_ch_quart; //rotation pour le twist
Translate {-root_ch/4,0,0}{Point{1:(231*(nb_sec-1))+231};}//mettre toute les section au quart de la chord racine

Call Translate_sec; //création de l'aile en flèche
//Call coord_ch_quart; //rotation pour le twist
// rotation pour avoir l'axe y dans la direction de l'envergure de l'aile
xpt1[]=Point{1};
Rotate {{0, 0, 1}, {0, 0, 0}, -Pi} { Point{1:(231*(nb_sec-1))+231}; }
xpt1[]=Point{1};
Rotate {{0,1,0}, {0, 0, 0}, -Pi} { Point{1:(231*(nb_sec-1))+231}; }
//xpt1[]=Point{1};
Rotate {{1, 0, 0}, {0, 0, 0}, -Pi/2} { Point{1:(231*(nb_sec-1))+231}; }
//
// creation du profil à la racine
Spline(1)={1:116};
Spline(2)={116,231:118,1};
Curve Loop(1) = {2,1};
// creation du profil à l'extremite
Spline(4)={(231*(nb_sec-1)+1):((231*(nb_sec-1)+1)+114),((231*(nb_sec-1)+1)+115)};
Spline(5)={((231*(nb_sec-1)+1)+115),(231*(nb_sec-1)+1)+230:((231*(nb_sec-1)+1)+117),(231*(nb_sec-1)+1)};
Curve Loop(2) = {5,4};
//ligne du bord de fuite
spl_7[]={};
For i In {0:nb_sec-1}
	spl_7[i]=((231*i+1)+115);
EndFor
Spline(7)={spl_7[]};
//ligne du bor d'attaque
spl_8[]={};
spl_9[]={};
For i In {0:nb_sec-1}
	spl_9[i]=231*i+1;
EndFor
Spline(9)= {spl_9[]};
//creation des boucles pour la surface inferieure et superieure 
Curve Loop(3) = {7, -4, -9, 1};
Curve Loop(4) = {5, -9, -2, 7};
//
//surface et création volume
Plane Surface(1)={2};
Surface (2) = {3};
Surface (3) = {4};
Surface loop(1)={1,2,3};
Surface Loop(2) = {3, 35, 2, 1};
//+
Physical Surface("WING", 35) = {4, 2, 3, 1};

Coherence;

