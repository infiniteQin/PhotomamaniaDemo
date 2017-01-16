//
//  NetWork.swift
//  Photomania
//
//  Created by infiq on 2016/12/20.
//  Copyright © 2016年 Essan Parto. All rights reserved.
//

import Foundation
import Alamofire

enum BackendError : Error {
    case network(error: Error)
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case objectSerialization(error: String)
    case imageSerialization(error: String)
}

protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
}

protocol ResponseCollectionSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self]
}

extension DataRequest {

    /// 返回集合数据
    ///
    /// - Parameters:
    ///   - queue:
    ///   - completionHandler:
    /// - Returns:
    @discardableResult
    func responseCollection<T: ResponseCollectionSerializable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        let responseSerializer = DataResponseSerializer<[T]> {
            request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            guard let response = response else {
                let reason = "Response collection could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(error: reason))
            }
            
            return .success(T.collection(from: response, withRepresentation: jsonObject))
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    
    /// 返回任意实现了 ResponseObjectSerializable 接口的对象
    ///
    /// - Parameters:
    ///   - queue:
    ///   - completionHandler:
    /// - Returns:
    @discardableResult
    func responseObject<T: ResponseObjectSerializable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            guard let response = response, let responseObject = T(response: response, representation: jsonObject) else {
                let reason = "Response object could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(error: reason))
            }
            
            return .success(responseObject)
        }
        
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    @discardableResult
    func responseImage(queue: DispatchQueue? = nil, completionHandler: @escaping(DataResponse<UIImage>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.imageResponseSerializer(), completionHandler: completionHandler)
    }
    
    
    /// 图片序列化对象
    ///
    /// - Returns:
    static func imageResponseSerializer() -> DataResponseSerializer<UIImage> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!))}
            let respData = Request.serializeResponseData(response: response, data: data, error: error)
            guard case let .success(validData) = respData else {
                return .failure(BackendError.dataSerialization(error: respData.error as! AFError))
            }
            guard let image = UIImage(data: validData, scale: UIScreen.main.scale) else {
                return .failure(BackendError.imageSerialization(error: "数据序列化失败，或序列化图片为🈳️"))
            }
            return .success(image)
            
        }
    }

}

@discardableResult
public func request(
    _ url: URLConvertible)
    -> DataRequest
{
    return SessionManager.default.request(
        url,
        method: .get,
        parameters: nil,
        encoding: URLEncoding.default,
        headers: nil
    )
}
