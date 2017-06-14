//
//  EPUBParser.swift
//  Reader
//
//  Created by Witek on 09/06/2017.
//  Copyright © 2017 Witek Bobrowski. All rights reserved.
//

import Zip
import AEXML
import Foundation

public class EPUBParser {
    
    class public func parse(_ fileName: String) throws -> EPUBDocument {
        do {
            let directory = try unzip(fileName)
            let contentPath = try getContentPath(from: directory)
            let data = try Data(contentsOf: contentPath)
            let content = try AEXMLDocument(xml: data)
            let metadata = getMetadata(from: content.root["metadata"])
            let manifest = getManifest(from: content.root["manifest"])
            let spine =  getSpine(from: content.root["spine"])
            let tocPath = directory.appendingPathComponent("OEBPS/".appending(try manifest.getTOCPath(id: try spine.getTOCid())))
            let tocData = try Data(contentsOf: tocPath)
            let tocContent = try AEXMLDocument(xml: tocData)
            let toc = getTableOfContents(from: tocContent.root)
            return EPUBDocument(directory: directory, metadata: metadata, manifest: manifest, spine: spine, toc: toc)
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
    
    class private func unzip(_ name: String) throws -> URL {
        Zip.addCustomFileExtension("epub")
        do {
            let filePath = Bundle.main.url(forResource: name, withExtension: "epub")!
            let unzipDirectory = try Zip.quickUnzipFile(filePath)
            return unzipDirectory
        } catch ZipError.unzipFail {
            throw EPUBParserError.unZipError
        }
    }
    
    class private func getContentPath(from bookDirectory: URL) throws -> URL {
        do {
            let path = bookDirectory.appendingPathComponent("META-INF/container.xml")
            let data = try Data(contentsOf: path)
            let container = try AEXMLDocument(xml: data)
            let content = container.root["rootfiles"]["rootfile"].attributes["full-path"]
            return bookDirectory.appendingPathComponent(content!)
        } catch {
            throw EPUBParserError.containerParseError
        }
    }
    
    class private func getMetadata(from content: AEXMLElement) -> EPUBMetadata {
        let metadata = EPUBMetadata()
        metadata.contributor = EPUBCreator(name: content["dc:contributor"].value,
                                           role: content["dc:contributor"].attributes["opf:role"],
                                           fileAs: content["dc:contributor"].attributes["opf:file-as"])
        metadata.coverage = content["dc:coverage"].value
        metadata.creator = EPUBCreator(name: content["dc:creator"].value,
                                       role: content["dc:creator"].attributes["opf:role"],
                                       fileAs: content["dc:creator"].attributes["opf:file-as"])
        metadata.date = content["dc:date"].value
        metadata.description = content["dc:description"].value
        metadata.format = content["dc:format"].value
        metadata.identifier = content["dc:identifier"].value
        metadata.language = content["dc:language"].value
        metadata.publisher = content["dc:publisher"].value
        metadata.relation = content["dc:relation"].value
        metadata.rights = content["dc:rights"].value
        metadata.source = content["dc:source"].value
        metadata.subject = content["dc:subject"].value
        metadata.title = content["dc:title"].value
        metadata.type = content["dc:type"].value
        return metadata
    }
    
    class private func getManifest(from content: AEXMLElement) -> EPUBManifest {
        var children: [String:EPUBManifestItem] = [:]
        for item in content["item"].all! {
            let id = item.attributes["id"]!
            let path = item.attributes["href"]!
            let mediatype = item.attributes["media-type"]
            let properties = item.attributes["properties"]
            children[id] = EPUBManifestItem(id: id, path: path, mediaType: mediatype!, property: properties)
        }
        if let id = content["id"].value {
            return EPUBManifest(id: id, children: children)
        } else {
            return EPUBManifest(children: children)
        }
    }
    
    class private func getSpine(from content: AEXMLElement) -> EPUBSpine {
        var children: [EPUBSpineItem] = []
        for item in content["itemref"].all! {
            if let linear = item["linear"].value {
                children.append(EPUBSpineItem(id: item["id"].value, idref: item["idref"].value!, linear: linear == "yes" ? true : false))
            } else {
                children.append(EPUBSpineItem(id: item.attributes["id"], idref: item.attributes["idref"]!))
            }
        }
        if let ppd = content["page-progression-direction"].value {
            return EPUBSpine(id: content["id"].value, toc: content.attributes["toc"], pageProgressionDirection: ppd == "ltr" ? .leftToRight : .rightToLeft , children: children)
        } else {
            return EPUBSpine(id: content["id"].value, toc: content.attributes["toc"], children: children)
        }
    }

    class private func getTableOfContents(from toc: AEXMLElement) -> EPUBTableOfContents {
        let item = toc["head"]["meta"].all(withAttributes: ["name":"dtb=uid"])?.first?.attributes["content"]
        let tableOfContents = EPUBTableOfContents(label: toc["docTitle"]["text"].value!, id: "0", item: item, subTable: [])
        
        func evaluateChildren(from map: AEXMLElement) -> [EPUBTableOfContents]{
            if let _ = map["navPoint"].all {
                var subs: [EPUBTableOfContents] = []
                for point in map["navPoint"].all! {
                    subs.append(EPUBTableOfContents(label: point["navLabel"]["text"].value!, id: point.attributes["id"]!, item: point["content"].attributes["src"]!, subTable: evaluateChildren(from: point["navMap"])))
                }
                return subs
            } else {
                return []
            }
        }
        tableOfContents.subTable = evaluateChildren(from: toc["navMap"])
        return tableOfContents
    }
    
}


