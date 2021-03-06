(** Copyright (c) 2016-present, Facebook, Inc.

    This source code is licensed under the MIT license found in the
    LICENSE file in the root directory of this source tree. *)

open Core
open OUnit2

open Ast
open Plugin

open Test


let test_transform_ast _ =
  let assert_expand ?(qualifier = "qualifier") source expected =
    let parse =
      parse ~qualifier:(Source.qualifier ~path:qualifier)
    in
    assert_source_equal
      (parse expected)
      (NamedTuples.transform_ast (parse source))
  in
  assert_expand
    {|
      $local_qualifier$T = typing.NamedTuple('T')
    |}
    {|
      class qualifier.T(typing.NamedTuple):
        pass
    |};
  assert_expand
    {|
      T = collections.namedtuple('T', ['a'])
    |}
    {|
      class T(typing.NamedTuple):
        T.a: typing.Any
    |};
  assert_expand
    {|
      T = typing.NamedTuple('T', ['one', 'two'])
    |}
    {|
      class T(typing.NamedTuple):
        T.one: typing.Any
        T.two: typing.Any
    |};
  assert_expand
    {|
      T = typing.NamedTuple('T', [('one', int), ('two', str)])
    |}
    {|
      class T(typing.NamedTuple):
        T.one: int
        T.two: str
    |};
  assert_expand
    {|
      T = collections.namedtuple('T', 'a b c')
    |}
    {|
      class T(typing.NamedTuple):
        T.a: typing.Any
        T.b: typing.Any
        T.c: typing.Any
    |};

  assert_expand
    {|
      class Foo(Bar, collections.namedtuple('T', ['one', 'two'])):
        Foo.three: int = 1
    |}
    {|
      class Foo(Bar, typing.NamedTuple):
        Foo.one: typing.Any
        Foo.two: typing.Any
        Foo.three: int = 1
    |};

  (* Don't transform non-toplevel statements. *)
  assert_expand
    {|
      def foo():
        T = typing.NamedTuple('T')
    |}
    {|
      def foo():
        T = typing.NamedTuple('T')
    |}


let () =
  "plugin_named_tuples">:::[
    "transform_ast">::test_transform_ast;
  ]
  |> run_test_tt_main
