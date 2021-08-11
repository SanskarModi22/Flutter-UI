import 'dart:convert';
import 'package:books_app/constants/error.dart';
import 'package:books_app/Utils/backend/book_requests.dart';
import 'package:books_app/Utils/helpers.dart';
import 'package:books_app/Utils/keys_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'book.dart';

class Books with ChangeNotifier {
  //Owned Books
  final List<Book> _ownedBooks = <Book>[];

  //Lent Books
  final List<Book> _lentBooks = <Book>[];

  //Borrowed Books
  final List<Book> _borrowedBooks = <Book>[];

  //Saved Books

  List<Book> _savedBooks = <Book>[];

  //Getters for Book List
  final List<Book> _within3km = <Book>[];

  final List<Book> _within5km = <Book>[];

  final List<Book> _within10km = <Book>[];

  final List<Book> _within20km = <Book>[];

  //Filtering Functions
  //A-Z
  final List<Book> _recommendedBooks = <Book>[];

  //Z-A
  final List<Book> _discoverNew = <Book>[];

  //Author
  List<Book> get borrowedBooks {
    return _borrowedBooks;
  }

  //Ratings highest to lowest
  List<Book> get discoverNew {
    return <Book>[..._discoverNew];
  }

  //********EXPLORE NEARBY TO BE IMPLEMENTED*******///

  List<Book> get lentBooks {
    return _lentBooks;
  }

//Lent Books
  List<Book> get ownedBooks {
    return _ownedBooks;
  }

//Borrowed Books
  List<Book> get recommendedBooks {
    return <Book>[..._recommendedBooks];
  }

//Saved Books

  List<Book> get savedBooks {
    _savedBooks = <Book>[];
    print('Getter SavedBooks called');
    for (final Book book in _recommendedBooks) {
      if (book.isBookMarked) {
        _savedBooks.insert(0, book);
        print('${book.title} Book Inserted in SavedBook List');
      }
    }
    for (final Book book in _discoverNew) {
      if (book.isBookMarked) {
        _savedBooks.insert(0, book);
        print('${book.title} Book Inserted in SavedBook List');
      }
    }
    return _savedBooks;
  }

//*******GETTERS
  List<Book> get within10km {
    return <Book>[..._within10km];
  }

  List<Book> get within20km {
    return <Book>[..._within20km];
  }

  List<Book> get within3km {
    return <Book>[..._within3km];
  }

  List<Book> get within5km {
    return <Book>[..._within5km];
  }

  Future<dynamic> getBooksbyISBN(String isbn) async {
    // const String url = 'https://www.googleapis.com/books/v1/volumes?q=isbn';
    final String token = await TokenStorage().loadAuthToken();
    try {
      // final http.Response response = await http.get(url + isbn);
      final Response response =
          await BookRequest.bookDataFromISBN(token, isbn);

      final dynamic result = await getBodyFromResponse(response);
      print('Result From get Books From ISBN:');

      print(result);
      if (result != null) {
        return result;
      }
      return null;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<dynamic> getISBNFromName(String title) async {
    const String url = 'https://www.googleapis.com/books/v1/volumes?q=';
    try {
      final http.Response response = await http.get(url + title);
      final dynamic resultJson = jsonDecode(response.body);
      if (resultJson != null) {
        final String isbn = resultJson['items'][0]['volumeInfo']
                ['industryIdentifiers'][1]['identifier']
            .toString();
        return isbn;
      }
      return null;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> getRecommendedBooks() async {
    const String recommendedURL =
        'https://explr-books.herokuapp.com/recommend_isbn/?isbn=9781448139859';
    try {
      final http.Response response = await http.get(recommendedURL);
      final dynamic result = jsonDecode(response.body);
      if (result != null) {
        final dynamic booksISBNList = json.decode(response.body);
        final int length = booksISBNList.length as int;
        print(response.body);
        final List<Book> recommendedBooks = <Book>[];
        for (int i = 0; i < length; i++) {
          final Future<dynamic> responseFromISBN =
              getBooksbyISBN(booksISBNList[i].toString());

          final Book book = makeBook(responseFromISBN);
          recommendedBooks.add(book);
        }
        return recommendedBooks;
      }
      return const Text('Result is null');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> postAddedBook(Book book) async {
    final String token = await TokenStorage().loadAuthToken();
    final Response response = await BookRequest.postBook(token, book);
    // const String recommendedURL =
    //     'https://explr-books.herokuapp.com/recommend_isbn/?isbn=9781448139859';
   
      // final http.Response response = await http.get(recommendedURL);
      final dynamic booksISBNList = await getBodyFromResponse(response);

      if (booksISBNList.statusCode == 201) {
        print(response.body);

        print('is the body of response in function postADDEDBook');
      }
      else{
 final int errorId = booksISBNList['error']['id'] as int;
    print('The error ID of loginWithSocialMedia made bu Piotr is $errorId');

    switch (errorId) {
      case Error.ISBN_NOT_FOUND:
        {
          throw Exception(
              'Book data with the provided isbn does not exist');
        }
      default:
        {
          throw Exception('An unknown error occured. Please try again later');
        }
    }
      }
    
    notifyListeners();
    
  }

  Book makeBook(dynamic result) {
    Book book;

    if (result != null) {
      final String title = result['volumeInfo']['title'].toString();
      final String author = result['volumeInfo']['authors'][0].toString();
      final String description = result['volumeInfo']['description'].toString();
      final String isbn = result['volumeInfo']['industryIdentifiers'][0]
              ['identifier']
          .toString();
      final String infoLink = result['volumeInfo']['infoLink'].toString();

      String imageLink;
      try {
        imageLink = result['volumeInfo']['imageLinks']['thumbnail'].toString();
        imageLink = imageLink.replaceFirst('http', 'https', 0);
      } catch (e) {
        imageLink =
            'https://images.unsplash.com/photo-1573488721809-e0f256ad3ad8?ixid=MXwxMjA3fDB8MHxzZWFyY2h8NTV8fG5vdmVsfGVufDB8fDB8&ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60';
      }
      print(imageLink.length);
      if (imageLink.isEmpty) {
        print('imageLink is empty');
      }

      book = Book(
        isbn: isbn,
        title: title,
        description: description,
        imageUrl: imageLink,
        author: author,
        infoLink: infoLink,
      );
    }
    return book;
  }

  void sortAuthor() {
    _within3km.sort((Book a, Book b) => a.author.compareTo(b.author));
    _within5km.sort((Book a, Book b) => a.author.compareTo(b.author));
    _within10km.sort((Book a, Book b) => a.author.compareTo(b.author));
    _within20km.sort((Book a, Book b) => a.author.compareTo(b.author));
    notifyListeners();
  }

  void sortAZ() {
    _within3km.sort((Book a, Book b) => a.title.compareTo(b.title));
    _within5km.sort((Book a, Book b) => a.title.compareTo(b.title));
    _within10km.sort((Book a, Book b) => a.title.compareTo(b.title));
    _within20km.sort((Book a, Book b) => a.title.compareTo(b.title));
    notifyListeners();
  }

  void sortRating() {
    _within3km.sort((Book b, Book a) => a.rating.compareTo(b.rating));
    _within5km.sort((Book b, Book a) => a.rating.compareTo(b.rating));
    _within10km.sort((Book b, Book a) => a.rating.compareTo(b.rating));
    _within20km.sort((Book b, Book a) => a.rating.compareTo(b.rating));
    notifyListeners();
  }

  //1.1 Convert Response to a Book Object

  //Helper-Get Book ISBN From Name
  void sortZA() {
    _within3km.sort((Book b, Book a) => a.title.compareTo(b.title));
    _within5km.sort((Book b, Book a) => a.title.compareTo(b.title));
    _within10km.sort((Book b, Book a) => a.title.compareTo(b.title));
    _within20km.sort((Book b, Book a) => a.title.compareTo(b.title));
    notifyListeners();
  }

  Future<dynamic> topBooks() async {
    const String recommendedURL =
        'https://www.googleapis.com/books/v1/volumes?q=isbn';

    try {
      final http.Response response = await http.get(Uri.parse(recommendedURL));
      final dynamic result = jsonDecode(response.body);
      print('result from Google API topBook func is $result');
      final List list = result['items'] as List;

      if (result != null) {
        final List<Book> recommendedBooks = <Book>[];

        for (dynamic value in list) {
          recommendedBooks.add(makeBook(value));
        }
        return recommendedBooks;
      }
      return const Text('Result is null');
    } catch (e) {
      print(e.toString());
    }
  }
}