import 'package:flutter/material.dart';

void main() {
  runApp(const ChessGameApp());
}

class ChessGameApp extends StatelessWidget {
  const ChessGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chess',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChessGameScreen(),
    );
  }
}

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key});

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late List<List<ChessPiece?>> board;
  Position? selectedSquare;
  Set<Position> legalMoves = {};
  PieceColor currentTurn = PieceColor.white;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));

    final backRank = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];

    for (int col = 0; col < 8; col++) {
      board[0][col] = ChessPiece(backRank[col], PieceColor.black);
      board[1][col] = ChessPiece(PieceType.pawn, PieceColor.black);
      board[6][col] = ChessPiece(PieceType.pawn, PieceColor.white);
      board[7][col] = ChessPiece(backRank[col], PieceColor.white);
    }

    selectedSquare = null;
    legalMoves = {};
    currentTurn = PieceColor.white;
  }

  void _onSquareTapped(int row, int col) {
    final clicked = Position(row, col);

    if (selectedSquare == null) {
      final piece = board[row][col];
      if (piece != null && piece.color == currentTurn) {
        selectedSquare = clicked;
        legalMoves = _getLegalMovesFor(selectedSquare!);
        setState(() {});
      }
      return;
    }

    if (legalMoves.contains(clicked)) {
      final from = selectedSquare!;
      final movingPiece = board[from.row][from.col]!;

      board[row][col] = movingPiece;
      board[from.row][from.col] = null;

      selectedSquare = null;
      legalMoves = {};
      currentTurn = (currentTurn == PieceColor.white)
          ? PieceColor.black
          : PieceColor.white;

      setState(() {});
      return;
    }

    final piece = board[row][col];
    if (piece != null && piece.color == currentTurn) {
      selectedSquare = clicked;
      legalMoves = _getLegalMovesFor(selectedSquare!);
      setState(() {});
      return;
    }

    selectedSquare = null;
    legalMoves = {};
    setState(() {});
  }

  Set<Position> _getLegalMovesFor(Position from) {
    final piece = board[from.row][from.col];
    if (piece == null) return {};

    final moves = <Position>{};

    switch (piece.type) {
      case PieceType.pawn:
        _addPawnMoves(from, piece.color, moves);
        break;
      case PieceType.rook:
        _addSlidingMoves(from, piece.color, moves, [
          const Position(-1, 0),
          const Position(1, 0),
          const Position(0, -1),
          const Position(0, 1),
        ]);
        break;
      case PieceType.bishop:
        _addSlidingMoves(from, piece.color, moves, [
          const Position(-1, -1),
          const Position(-1, 1),
          const Position(1, -1),
          const Position(1, 1),
        ]);
        break;
      case PieceType.queen:
        _addSlidingMoves(from, piece.color, moves, [
          const Position(-1, 0),
          const Position(1, 0),
          const Position(0, -1),
          const Position(0, 1),
          const Position(-1, -1),
          const Position(-1, 1),
          const Position(1, -1),
          const Position(1, 1),
        ]);
        break;
      case PieceType.knight:
        final offsets = [
          const Position(-2, -1),
          const Position(-2, 1),
          const Position(-1, -2),
          const Position(-1, 2),
          const Position(1, -2),
          const Position(1, 2),
          const Position(2, -1),
          const Position(2, 1),
        ];
        for (final offset in offsets) {
          final row = from.row + offset.row;
          final col = from.col + offset.col;
          if (_isInsideBoard(row, col)) {
            final target = board[row][col];
            if (target == null || target.color != piece.color) {
              moves.add(Position(row, col));
            }
          }
        }
        break;
      case PieceType.king:
        final offsets = [
          const Position(-1, -1),
          const Position(-1, 0),
          const Position(-1, 1),
          const Position(0, -1),
          const Position(0, 1),
          const Position(1, -1),
          const Position(1, 0),
          const Position(1, 1),
        ];

        for (final offset in offsets) {
          final row = from.row + offset.row;
          final col = from.col + offset.col;
          if (_isInsideBoard(row, col)) {
            final target = board[row][col];
            if (target == null || target.color != piece.color) {
              moves.add(Position(row, col));
            }
          }
        }
        break;
    }

    return moves;
  }

  void _addPawnMoves(Position from, PieceColor color, Set<Position> moves) {
    final direction = color == PieceColor.white ? -1 : 1;
    final startingRow = color == PieceColor.white ? 6 : 1;

    final oneStepRow = from.row + direction;
    if (_isInsideBoard(oneStepRow, from.col) &&
        board[oneStepRow][from.col] == null) {
      moves.add(Position(oneStepRow, from.col));

      final twoStepRow = from.row + (direction * 2);
      if (from.row == startingRow &&
          _isInsideBoard(twoStepRow, from.col) &&
          board[twoStepRow][from.col] == null) {
        moves.add(Position(twoStepRow, from.col));
      }
    }

    for (final colOffset in [-1, 1]) {
      final checkRow = from.row + direction;
      final checkCol = from.col + colOffset;

      if (_isInsideBoard(checkRow, checkCol)) {
        final target = board[checkRow][checkCol];
        if (target != null && target.color != color) {
          moves.add(Position(checkRow, checkCol));
        }
      }
    }
  }

  void _addSlidingMoves(Position from, PieceColor color, Set<Position> moves,
      List<Position> directions) {
    for (final dir in directions) {
      int row = from.row + dir.row;
      int col = from.col + dir.col;

      while (_isInsideBoard(row, col)) {
        final target = board[row][col];
        if (target == null) {
          moves.add(Position(row, col));
        } else {
          if (target.color != color) {
            moves.add(Position(row, col));
          }
          break;
        }

        row += dir.row;
        col += dir.col;
      }
    }
  }

  bool _isInsideBoard(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetBoard,
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 420,
          height: 420,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GridView.builder(
            itemCount: 64,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              final piece = board[row][col];
              final isSelected =
                  selectedSquare != null &&
                  selectedSquare!.row == row &&
                  selectedSquare!.col == col;
              final isLegalMove = legalMoves.contains(Position(row, col));

              return GestureDetector(
                onTap: () => _onSquareTapped(row, col),
                child: Container(
                  decoration: BoxDecoration(
                    color: (row + col) % 2 == 0
                        ? const Color(0xFFF0D9B5)
                        : const Color(0xFFB58863),
                    border: isSelected
                        ? Border.all(color: Colors.yellow, width: 3)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (isLegalMove)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (piece != null)
                        Center(
                          child: Text(
                            piece.symbol,
                            style: TextStyle(
                              fontSize: 30,
                              color: piece.color == PieceColor.white
                                  ? Colors.white
                                  : Colors.black,
                              shadows: [
                                Shadow(
                                  blurRadius: 1,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum PieceType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king,
}

enum PieceColor {
  white,
  black,
}

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  ChessPiece(this.type, this.color);

  String get symbol {
    switch (type) {
      case PieceType.pawn:
        return color == PieceColor.white ? '♙' : '♟';
      case PieceType.rook:
        return color == PieceColor.white ? '♖' : '♜';
      case PieceType.knight:
        return color == PieceColor.white ? '♘' : '♞';
      case PieceType.bishop:
        return color == PieceColor.white ? '♗' : '♝';
      case PieceType.queen:
        return color == PieceColor.white ? '♕' : '♛';
      case PieceType.king:
        return color == PieceColor.white ? '♔' : '♚';
    }
  }
}

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
