//
//  Musician.swift
//  JazzyApp
//

/**
Musician models jazz musicians.
From Ellington to Marsalis, this class has you covered.
*/
class Musician {
    /// The name of the musician. i.e. "John Coltrane"
    var name: String

    /// The year the musician was born. i.e. 1926
    var birthyear: UInt

    /**
    Initialize a Musician.
    Don't forget to have a name and a birthyear.

    :param: name      The name of the musician.
    :param: birthyear The year the musician was born.

    :returns:          An initialized Musician instance.
    */
    init(name: String, birthyear: UInt) {
        self.name = name
        self.birthyear = birthyear
    }
}
