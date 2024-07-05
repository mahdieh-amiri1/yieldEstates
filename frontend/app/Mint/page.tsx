'use client'
import { useState,useEffect } from 'react';
import Button from '@mui/material/Button';
import { Grid, Typography } from '@mui/material';
import ImageUploadToIPFS from '../Components/FileUpload';
import { useAccount,useWriteContract,useWaitForTransactionReceipt } from 'wagmi';
import { erc20Abi, maxUint256 } from 'viem';
import { RealEStateNFTContractAddress, MarketPlaceContractAddress } from '../Constants/contracts';
import { selectedChain } from '../Utils/client';
import { RealEstateNFTABI } from '../ABIs/RealEStateNFTABI';
import { error } from 'console';

function Mint() {
  const account = useAccount();
  const [cid,setCid] = useState<string|undefined>(undefined);
  const [tokenId,setTokenId] = useState<string|undefined>(undefined);
  const [reservable,setReservable] = useState<boolean>(false);
  const { data: mintHash,isError:IsMintError,error:mintError, writeContract:mintWriteContract } = useWriteContract();
  const {isLoading:mintLoading,isSuccess:mintSuccess}= useWaitForTransactionReceipt({hash:mintHash});
  const mint = async()=>{
    if(account.isConnected && cid)
    mintWriteContract({
      address: RealEStateNFTContractAddress,
      abi: RealEstateNFTABI,
      functionName: 'mint',
      args: [ account.address!,BigInt(1000),BigInt(1000),cid!,BigInt(1000),"" as "0x${string}"]
    });
    // mintWriteContract({
    //   address: RealEStateNFTContractAddress,
    //   abi: RealEstateNFTABI,
    //   functionName: 'burn',
    //   args: [ account.address!,BigInt(1),BigInt(500)]
    // });
  }
  // const { config:FNFTConfig } = usePrepareContractWrite({
  //   address: "FractionalizeNFTContractAddress",
  //   abi: erc20Abi,
  //   functionName: 'mint',
  //   args: [account.address, tokenId,cid, reservable, account.address],
  //   enabled: Boolean(account.address && cid && tokenId && reservable!=null && account.address),
  // })
  // const { data:FNFTData ,write:FNFTWrite } = useContractWrite(FNFTConfig);
  // const { config:ReserveConfig } = usePrepareContractWrite({
  //   address: "FReserverContractAddress",
  //   abi: erc20Abi,
  //   functionName: 'reserve',
  //   args: [tokenId],
  //   enabled: Boolean(tokenId),
  // })
  // const { data:ReserveData ,write:ReserveWrite } = useContractWrite(ReserveConfig);
  // const { isLoading:isLoadingReserve, isSuccess:isSuccessReserve } = useWaitForTransaction({
  //   hash: ReserveData?.hash,
  // })
  // const { isLoading, isSuccess } = useWaitForTransaction({
  //   hash: FNFTData?.hash,
  // })
  // useEffect(()=>{
  //   if(isSuccessReserve){
  //     setReservable(true);
  //   }
  // },[isSuccessReserve]);
  useEffect(()=>{
    if(mintError){
      console.log("mint Error:", mintError)
    }
  },[IsMintError]);
  return (
  <Grid container justifyContent={'Left'} spacing={3} padding={7} direction="column" alignItems={'Left'}>
    <ImageUploadToIPFS cid = {cid} setCid = {setCid}/>
    {mintLoading && <Typography>Minting</Typography>}
    {mintSuccess && 
        <div>
          Successfully minted your NFT!
          <div>
            <a href={`${selectedChain.blockExplorers.default.url}/tx/${mintHash}`}>Transaction Link</a>
          </div>
        </div>
      }
    <Button className="nice_but" disabled={cid == undefined } onClick={()=>{ console.log("Trying to mint...",cid,account.address);mint(); }}>
       Mint
    </Button>
  </Grid>

  );
}
  
export default Mint;