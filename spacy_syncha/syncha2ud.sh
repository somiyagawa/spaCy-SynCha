#! /bin/sh
cat ${1+"$@"} | syncha -n 0 | awk '
BEGIN{
  xp["接頭辞"]=xp["接頭詞"]=xp["接尾辞"]="PART";
  xp["代名詞"]="PRON";
  xp["連体詞"]="DET";
  xp["動詞"]="VERB";
  xp["助動詞"]="AUX";
  xp["形容詞"]=xp["形状詞"]="ADJ";
  xp["副詞"]="ADV";
  xp["感動詞"]=xp["フィラー"]="INTJ";
  xp["接続詞"]="CCONJ";
  xp["補助記号"]=xp["空白"]="PUNCT";
  bhead[-1]=0;
  n=0;
}
{
  if($0~/^\* [0-9]+ /){
    b=$2;
    bfrom[b]=substr($3,1,length($3)-1);
    bhead[b]=substr($4,1,index($4,"/")-1)+n+1;
    id[b]=ga[b]=ni[b]=o[b]=-1;
  }
  else if($0=="EOS"){
    for(i=0;i<b;i++)
      head[bhead[i]]=bhead[bfrom[i]];
    for(i=1;i<=n;i++){
      j=split(tags[i],a,",");
      if(j<7||a[7]==""||a[7]=="*")
        lemma[i]=form[i];
      else
        lemma[i]=a[7];
      if(j<8||a[8]==""||a[8]==form[i])
        misc[i]="SpaceAfter=No";
      else
        misc[i]="SpaceAfter=No|Translit="a[8];
      upos[i]=xp[a[1]];
      xpos[i]=a[1];
      for(j=2;j<5;j++){
        if(a[j]=="*")
          break;
        xpos[i]=sprintf("%s-%s",xpos[i],a[j]);
      }
      if(a[1]=="名詞"){
        upos[i]="NOUN";
        if(a[2]=="固有名詞")
          upos[i]="PROPN";
        else if(a[2]=="数詞"||a[2]=="数")
          upos[i]="NUM";
        else if(a[2]=="代名詞")
          upos[i]="PRON";
      }
      else if(a[1]=="助詞"){
        upos[i]="ADP";
        if(a[2]=="接続助詞"){
          if(lemma[i]=="て")
            upos[i]="SCONJ";
          else
            upos[i]="CCONJ";
        }
        else if(a[2]=="終助詞")
          upos[i]="PART";
      }
      else if(a[1]=="記号"){
        upos[i]="SYM"
        if(a[2]~/^(句点|読点|括弧(開|閉))$/)
          upos[i]="PUNCT";
      }
      if(upos[i]=="")
        upos[i]="X";
    }
    for(i=1;i<=n;i++){
      j=i-bhead[chunk[i]];
      if(j>0){
        if(upos[i]=="VERB")
          upos[i]="AUX";
        else if(upos[i]=="NOUN")
          upos[i]="ADP";
      }
    }
    for(i=1;i<=n;i++){
      if(head[i]==0)
        deprel[i]="root";
      else if(upos[i]~/^(PUNCT|SYM)$/)
        deprel[i]="punct";
      else if(upos[i]=="INTJ")
        deprel[i]="discourse";
      else if(upos[i]=="NUM")
        deprel[i]="nummod";
      else if(upos[i]=="ADV")
        deprel[i]="advmod";
      else if(upos[i]~/^(ADP|[SC]CONJ)$/){
        if(upos[head[i]]~/^(VERB|ADJ)$/)
          deprel[i]="mark";
        else
          deprel[i]="case";
      }
      else if(upos[i]=="AUX"){
        if(upos[head[i]]~/^(VERB|ADJ)$/)
          deprel[i]="aux";
        else
          deprel[i]="cop";
      }
      else{
        deprel[i]="dep";
        j=i-bhead[chunk[i]];
        if(j==0){
          x=id[chunk[i]];
          if(x!=-1){
            y=chunk[head[i]];
            if(upos[i]~/^(VERB|ADJ)$/){
              if(x==ga[y])
                deprel[i]="csubj";
              else if(x==ni[y])
                deprel[i]="advcl";
              else if(x==o[y])
                deprel[i]="ccomp";
              else
                x=-1;
            }
            else if(x==ga[y])
              deprel[i]="nsubj";
            else if(x==ni[y])
              deprel[i]="iobj";
            else if(x==o[y])
              deprel[i]="obj";
            else
              x=-1;
          }
          if(x==-1){
            if(upos[i]~/^(VERB|ADJ)$/){
              if(upos[head[i]]~/^(VERB|ADJ)$/)
                deprel[i]="advcl";
              else
                deprel[i]="acl";
            }
            else if(upos[head[i]]~/^(VERB|ADJ)$/){
              if(xpos[i+1]=="助詞-終助詞")
                deprel[i]="vocative";
              else
                deprel[i]="obl";
            }
            else if(upos[i]=="DET")
              deprel[i]="det";
            else
              deprel[i]="nmod";
          }
        }
        else if(j<0){
          if(upos[head[i]]~/^(VERB|ADJ)$/){
            if(upos[i]=="PART")
              deprel[i]="advmod";
            else
              deprel[i]="obl";
          }
          else
            deprel[i]="compound";
        }
        else{
          if(upos[i]=="PART")
            deprel[i]="mark";
        }
      }
    }
    for(i=1;i<=n;i++)
      printf("%d\t%s\t%s\t%s\t%s\t_\t%d\t%s\t_\t%s\n",i,form[i],lemma[i],upos[i],xpos[i],head[i],deprel[i],misc[i]);
    printf("\n");
    n=0;
  }
  else{
    i=split($0,a,"\t");
    if(i<2)
      next;
    n++;
    form[n]=a[1];
    tags[n]=a[2];
    chunk[n]=b;
    if(i>3){
      j=split(a[4],k);
      for(i=1;i<=j;i++){
        if(k[i]~/^id="/)
          id[b]=substr(k[i],5,length(k[i])-5);
        else if(k[i]~/^ga="/)
          ga[b]=substr(k[i],5,length(k[i])-5);
        else if(k[i]~/^ni="/)
          ni[b]=substr(k[i],5,length(k[i])-5);
        else if(k[i]~/^o="/)
          o[b]=substr(k[i],4,length(k[i])-4);
      }
    }
    if(bhead[b]==n)
      head[n]=0;
    else
      head[n]=bhead[b];
  }
}'
exit 0
