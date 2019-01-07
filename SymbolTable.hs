module SymbolTable where

import Data.List
import Data.Maybe

{-
Author: Soubhik Ghosh, Modified by Jonah Shafran
11/5/2018
-}

data Counts = Counts Int [(String, Int)] deriving (Show)
data Temps = Temps (Counts, Counts, Counts) deriving (Show)
data Table = Table Int Temps deriving (Show)

-- Get a new label
getLabel :: Table -> (Table, String)
getLabel (Table a b) = ((Table (a + 1) b), "LABEL_" ++ (show a))

-- Add a variable/identifier to the current scope in the symbol table
addEntry :: Table -> String -> String -> Table
addEntry (Table lc (Temps (Counts c1 t1, Counts c2 t2, Counts c3 t3))) scope value
 | scope == "global" = (Table lc (Temps (Counts (c1 + 1) ((value, c1):t1), Counts c2 t2, Counts c3 t3)))
 | scope == "local" = (Table lc (Temps (Counts c1 t1, Counts (c2 + 1) ((value, c2):t2), Counts c3 t3)))
 | scope == "param" = (Table lc (Temps (Counts c1 t1, Counts c2 t2, Counts (c3+1) ((value,c3):t3))))

-- Add a local temporary in the symbol table
addTemp :: Table -> (Table, String)
addTemp (Table lc (Temps (Counts c1 t1, Counts c2 t2, t3))) =
 (Table lc (Temps (Counts c1 t1, Counts (c2+1) t2, t3)), "mem[base + " ++ (show c2) ++ "]")

-- Get corresponding temporary for the variable/identifier in order of param -> local -> global
getVar :: Table -> String -> String
getVar (Table lc (Temps (Counts c1 t1, Counts c2 t2, Counts c3 t3))) value
 | any (checkup value) t3 =
   let (Just (_,index)) = find (checkup value) t3 in
   "mem[base - " ++ (show (c3-index+4)) ++ "]"
 | any (checkup value) t2 =
   let (Just (_, index)) = find (checkup value) t2 in
   "mem[base + " ++ (show index) ++ "]"
 | any (checkup value) t1 =
   let (Just (_, index)) = find (checkup value) t1 in
   "mem[" ++ (show index) ++ "]"
 where checkup v (a, b) = if a == v then True else False

-- Print variable/identifier declarations
programDecls :: Table -> String -> String
programDecls (Table _ (Temps (Counts c1 _, Counts c2 _, _))) scope
 | scope == "global" = "long base = " ++ (show c1) ++ ";\nlong top = " ++ (show c1) ++ ";\n"
 | scope == "local" = "base = top;\ntop = base + " ++ (show c2) ++ ";\n"
