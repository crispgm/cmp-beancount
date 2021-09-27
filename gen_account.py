#!/usr/bin/env python3
import sys

from beancount.loader import load_file

if __name__ == '__main__':
    if len(sys.argv) > 1:
        fn = sys.argv[1]
        f = load_file(fn)
        print("return {")
        for item in f[0]:
            print("{label='%s'}," % (item.account))
        print("}")
    else:
        print("please input filename of beancount's account")
