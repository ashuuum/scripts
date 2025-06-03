#!/usr/bin/python3

import sys

if len(sys.argv)==1: 
	print("Usage: " + sys.argv[0] + " <usernames.txt>") 
	sys.exit(1) 

names = open(sys.argv[1],"r").read().strip().split('\n') 

list = []
for name in names: 
	n1, n2 = name.split(' ') 
	list.append(n1) 
	list.append(n1+n2) 
	list.append(n1+"."+n2) 
	list.append(n1+"-"+n2) 
	list.append(n1+"_"+n2) 
	list.append(n1+n2[0]) 
	list.append(n1+"."+n2[0]) 
	list.append(n1+"-"+n2[0]) 
	list.append(n1+"_"+n2[0]) 
	list.append(n2[0]+n1) 
	list.append(n2[0]+"."+n1) 
	list.append(n2[0]+"-"+n1) 
	list.append(n2[0]+"_"+n1) 
	list.append(n2) 
	list.append(n2+n1) 
	list.append(n2+"."+n1) 
	list.append(n2+"-"+n1) 
	list.append(n2+"_"+n1) 
	list.append(n2+n1[0]) 
	list.append(n2+"."+n1[0]) 
	list.append(n2+"-"+n1[0]) 
	list.append(n2+"_"+n1[0]) 
	list.append(n1[0]+n2) 
	list.append(n1[0]+"."+n2) 
	list.append(n1[0]+"-"+n2)
	list.append(n1[0]+"_"+n2) 
	
for n in list: 
	print(n)
