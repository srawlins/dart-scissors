// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
library scissors.src.css_mirroring.entity;

import 'package:quiver/check.dart';
import 'package:csslib/visitor.dart';

import 'buffered_transaction.dart';
import 'edit_configuration.dart';

class Entity<T extends TreeNode> {
  final String _source;
  final List<T> _list;
  final int _index;
  final Entity _parent;
  Entity(this._source, this._list, this._index, this._parent);

  T get value {
    return _list[_index];
  }

  int get startOffset => _getNodeStart(value);
  int get endOffset {
    var value = this.value;
    if (value is Declaration) {
      return getDeclarationEnd(_source, _list, _index);
    } else {
      /// If it is the last rule of ruleset delete rule till the end of parent which is
      /// document end in case of a toplevel ruleset and is directive end if ruleset is
      /// part of a toplevel directive like @media directive.
      return _index < _list.length - 1
          ? _getNodeStart(_list[_index + 1])
          : _parent?.endOffset ?? _source.length;
    }
  }

  void remove(BufferedTransaction trans) {
    trans.edit(startOffset, endOffset, '');
  }

  void prepend(BufferedTransaction trans, String s) {
    var start = startOffset;
    trans.edit(start, start, s);
  }
}

class FlippableEntity<T extends TreeNode> {
  final FlippableEntities<T> _entities;
  final int index;
  final FlippableEntity parent;
  FlippableEntity(this._entities, this.index, this.parent) {
    checkState(original.runtimeType == flipped.runtimeType,
        message: () => 'Mismatching entity types: '
            'original is ${original.runtimeType}, '
            'flipped is ${flipped.runtimeType}');
  }

  void remove(RetentionMode mode, BufferedTransaction trans) =>
      choose(mode).remove(trans);

  Entity<T> choose(RetentionMode mode) =>
      mode == RetentionMode.keepFlippedBidiSpecific ? flipped : original;

  Entity<T> get original => new Entity<T>(
      _entities.originalSource, _entities.originals, index, parent?.original);

  Entity<T> get flipped => new Entity<T>(
      _entities.flippedSource, _entities.flippeds, index, parent?.flipped);

  FlippableEntities<dynamic> getChildren(
      List<dynamic> getEntityChildren(T value)) {
    return new FlippableEntities(
        _entities.originalSource,
        getEntityChildren(original.value),
        _entities.flippedSource,
        getEntityChildren(flipped.value));
  }
}

class FlippableEntities<T extends TreeNode> {
  final String originalSource;
  final List<T> originals;

  final String flippedSource;
  final List<T> flippeds;

  final FlippableEntity parent;

  FlippableEntities(
      this.originalSource, this.originals, this.flippedSource, this.flippeds,
      {this.parent}) {
    assert(originals.length == flippeds.length);
  }

  get length => originals.length;

  void forEach(void process(FlippableEntity<T> entity)) {
    for (int i = 0; i < originals.length; i++) {
      process(new FlippableEntity<T>(this, i, parent));
    }
  }
}

int _getNodeStart(TreeNode node) {
  if (node is Directive) {
    // The node span start does not include '@' so additional -1 is required.
    return node.span.start.offset - 1;
  }
  return node.span.start.offset;
}

int getDeclarationEnd(String source, List decls, int iDecl) {
  if (iDecl < decls.length - 1) {
    return decls[iDecl + 1].span.start.offset;
  }

  final int fileLength = source.length;
  int fromIndex = decls[iDecl].span.end.offset;
  try {
    while (fromIndex + 1 < fileLength) {
      if (source.substring(fromIndex, fromIndex + 2) == '/*') {
        while (source.substring(fromIndex, fromIndex + 2) != '*/') {
          fromIndex++;
        }
      } else if (source[fromIndex] == '}') {
        return fromIndex;
      }
      fromIndex++;
    }
  } on RangeError catch (_) {
    throw new ArgumentError('Invalid CSS');
  }
  // Case when it doesnot find the end of declaration till file end.
  if (source[fromIndex] == '}') {
    return fromIndex;
  }
  throw new ArgumentError('Declaration end not found');
}
