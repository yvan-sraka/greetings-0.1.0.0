{-# LANGUAGE ForeignFunctionInterface #-}

module Greetings (hello) where

import Foreign.C.String (CString, newCString)
foreign import ccall unsafe "c_hello" c_hello :: CString -> IO ()

hello :: String -> IO ()
hello str = do
  c_str <- newCString str
  c_hello c_str
