module Main (main) where

import Control.Monad
    ( unless
    , when
    )
import Data.Maybe
    ( fromJust
    , fromMaybe
    )
import qualified Distribution.PackageDescription as PD
import Distribution.Simple
    ( Args
    , UserHooks
    , buildHook
    , confHook
    , defaultMainWithHooks
    , postClean
    , postConf
    , preConf
    , simpleUserHooks
    )
import Distribution.Simple.LocalBuildInfo
    ( LocalBuildInfo
    , configFlags
    , localPkgDescr
    )
import Distribution.Simple.Setup
    ( BuildFlags
    , CleanFlags
    , ConfigFlags
    , buildVerbosity
    , cleanVerbosity
    , configConfigurationsFlags
    , configVerbosity
    , fromFlag
    )
import Distribution.Simple.Utils (rawSystemExit)
import System.Directory
    ( doesDirectoryExist
    , getCurrentDirectory
    , removeDirectoryRecursive
    )


main :: IO ()
main = defaultMainWithHooks simpleUserHooks {
            preConf = rustPreConf,
           confHook = rustConfHook
       }


rustPreConf :: Args ->
                 ConfigFlags ->
                 IO PD.HookedBuildInfo
rustPreConf args flags = do
    buildInfo <- preConf simpleUserHooks args flags
    rawSystemExit (fromFlag $ configVerbosity flags) "cargo" ["build", "--release"]
    return buildInfo


rustConfHook :: (PD.GenericPackageDescription, PD.HookedBuildInfo) ->
                  ConfigFlags ->
                  IO LocalBuildInfo
rustConfHook (description, buildInfo) flags = do
    localBuildInfo <- confHook simpleUserHooks (description, buildInfo) flags
    let packageDescription = localPkgDescr localBuildInfo
        library = fromJust $ PD.library packageDescription
        libraryBuildInfo = PD.libBuildInfo library
    dir <- getCurrentDirectory
    return localBuildInfo {
        localPkgDescr = packageDescription {
            PD.library = Just $ library {
                PD.libBuildInfo = libraryBuildInfo {
                    PD.extraLibDirs = (dir ++ "/target/release"):PD.extraLibDirs libraryBuildInfo
                }
            }
        }
    }
