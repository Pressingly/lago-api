# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: books.proto

require 'google/protobuf'

descriptor_data = "\n\x0b\x62ooks.proto\x12\x05\x62ooks\"S\n\x04\x42ook\x12\n\n\x02id\x18\x01 \x01(\x05\x12\r\n\x05title\x18\x02 \x01(\t\x12\x13\n\x0b\x64\x65scription\x18\x03 \x01(\t\x12\x0c\n\x04tags\x18\x04 \x03(\t\x12\r\n\x05price\x18\x05 \x01(\x02\"#\n\x05\x42ooks\x12\x1a\n\x05\x62ooks\x18\x01 \x03(\x0b\x32\x0b.books.Book\"\r\n\x0b\x45mptyParams\"\x14\n\x06\x42ookID\x12\n\n\x02id\x18\x01 \x01(\x05\"\x1f\n\x0c\x42ookNotFound\x12\x0f\n\x07message\x18\x01 \x01(\t2f\n\x0b\x42ookService\x12.\n\x08GetBooks\x12\x12.books.EmptyParams\x1a\x0c.books.Books\"\x00\x12'\n\x07GetBook\x12\r.books.BookID\x1a\x0b.books.Book\"\x00\x62\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Books
  Book = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("books.Book").msgclass
  Books = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("books.Books").msgclass
  EmptyParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("books.EmptyParams").msgclass
  BookID = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("books.BookID").msgclass
  BookNotFound = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("books.BookNotFound").msgclass
end
