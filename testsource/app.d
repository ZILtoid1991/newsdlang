module app;

import std.path;
import std.file;
import std.stdio;
import newsdlang;

int main(string[] args) {
    int mustFailBadCount, mustPassBadCount;
    char[] fileBuffer;
    foreach (DirEntry mustFail ; dirEntries("./testcases/fail/", SpanMode.shallow)) {
        try {
            write("Reading file `", mustFail.name, "`, ");
            File f = File(mustFail.name);
            fileBuffer.length = cast(size_t)f.size;
            fileBuffer = f.rawRead(fileBuffer);
            readDOM(cast(string)fileBuffer);
            writeln("Error! Parser haven't thrown exception!");
        } catch (DLException e) {
            writeln("File failed successfully!");
        } catch (Exception e) {
            writeln("Misc. error: ", e);
        }
    }
    foreach (DirEntry mustPass ; dirEntries("./testcases/pass/", SpanMode.shallow)) {
        try {
            write("Reading file `", mustPass.name, "`, ");
            File f = File(mustPass.name);
            fileBuffer.length = cast(size_t)f.size;
            fileBuffer = f.rawRead(fileBuffer);
            readDOM(cast(string)fileBuffer);
            writeln("Pass!");
        } catch (DLException e) {
            writeln("Fail!");
        } catch (Exception e) {
            writeln("Misc. error: ", e);
        }
    }

    return 0;
}
