{-# LANGUAGE OverloadedStrings #-}
module Data.SVD.Extract (
    extractSVDCached
  , svd1
  ) where

import Turtle
import Prelude hiding (FilePath)
import Control.Monad
import qualified Control.Foldl as Fold
import qualified Data.Text as T
import qualified Data.ByteString.Char8 as B
import Data.Serialize

import Data.SVD.Parse
import Data.SVD.Types

-- parse SVD files into ("STM32F031x", Device {..} )
extractSVDCached :: FilePath -> IO [(String, Device)]
extractSVDCached dbPath = do
  dir <- pwd

  hasCache <- testfile $ decodeString $ cachePath
  case hasCache of
    True -> do
      putStrLn $ "Loading cached SVDs from " ++ cachePath
      cached <- B.readFile cachePath
      case decode cached of
        Left err -> fail err
        Right svds -> return svds

    False -> do
      putStrLn $ "Parsing SVDs from " ++ (encodeString dbPath)

      cd dbPath
      cd "svds/stm"
      svdxmls <- fold (onFiles (grepText (prefix "./STM32" <> suffix ".svd")) (ls ".")) Fold.list
      svds <- mapM svd1 $ map (T.unpack . format fp) svdxmls

      cd dir
      putStrLn $ "Saving cache to " ++ cachePath
      B.writeFile cachePath (encode svds)
      return svds
  where
    cachePath = "/tmp/data_stm32_svd_cache"

svd1 f = do
  res <- parseSVD f
  case res of
    Left e -> do
      die $ T.pack ("No parse of " ++ f ++ " error was " ++ e)
    Right x -> do
      return $ (drop 5 $ deviceName x, x)


