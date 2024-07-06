import axios from "axios";
import { RealEstateNFTABI } from "../ABIs/RealEStateNFTABI";
import { RealEStateNFTContractAddress } from "../Constants/contracts";
import { publicClient } from "../Utils/client";

export interface NFT{
    id: number,
    name: string,
    description: string,
    image: string
}
export const getAllNFTs = async():Promise<NFT[]> =>{
    const nfts = new Promise<NFT[]>(async(resolve,reject)=>{
    const totalSupply = await publicClient.readContract({
          address: RealEStateNFTContractAddress,
          abi: RealEstateNFTABI,
          functionName: 'totalSupply',
        })
        let tempNFTs:NFT[]=[];
        for( let i=1;i<totalSupply;i++){ 
          console.log("get URI:",i);

          const tokenURI = await publicClient.readContract({
            address: RealEStateNFTContractAddress,
            abi: RealEstateNFTABI,
            functionName: 'uri',
            args:[BigInt(i)]
            
          })
          
          console.log("token URI:", tokenURI);
          const cid:string = tokenURI.substring(13);
          const cid2 = cid.replaceAll('"',"");
          if(cid.length>45){
            const x = await axios.get("https://ipfs.io/ipfs/"+cid2);
            console.log('X: ', x)
            const result =x.data;
            result.id = i;
            tempNFTs.push(result);
          }
          
        }
        resolve(tempNFTs);
    })
    return nfts;
}
